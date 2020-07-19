# Teleport Integration Test Setup for Pub/Sub to MongoDB

The Pub/Sub to MongoDB Dataflow pipeline integration test has following system requirements:

 * Standalone MongoDB instance to be used as a pipeline sink
 * Cloud function to verify the Integration test result
 
This repository contains the scripts/steps needed to setup the standalone test instance as well as deploy cloud function.

Note that the same test instance is used by all the integration tests (staging, head, prod, release). 
The integration test will need to create unique records to distinguish between its messages.

### Prerequisites ###
* GKE Cluster must be set up and running. For details on how to set up cluster refer [GKE docs](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-cluster)

* Clone the current repository

#### Deploy MongoDB instance ####

1. Set up authentication to the GKE Cluster.

```shell
$ PROJECT=cloud-teleport-testing
$ ZONE=KuberentesZone # In case of Zonal cluster
$ cd pubsub-to-mongodb-test
$ gcloud container clusters  get-credentials <KuberentesClusterName> --zone ${KuberentesZone}
```

2. Deploy the manifest file.

```shell
$ kubectl apply -f teleport_mongodb_gkecluster.yaml
```

3. Get the Service end point IP address

```shell
$ kubectl get service/mongodb-ilb-service  --namespace default \
    --output jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

4. Confirm mongodb is running

```shell
$ PODNAME=$(kubectl get pods --namespace default -o=custom-columns='DATA:metadata.name' | grep mongodb-deployment)
$ kubectl exec -it ${PODNAME} -- /usr/bin/mongo
$ show dbs;
$ exit;
```

#### Deploy Cloud Function ####
```shell
$ PROJECT=cloud-teleport-testing
$ REGION=us-central1
$ CONNECTOR_NAME=vpc-conn-def-us-central1
$ gcloud -q functions deploy teleport-mongodb-verifier \
  --region=${REGION} --project=${PROJECT} \
  --runtime=python37 \
  --source="./cloudfunction" \
  --entry-point="verify" \
  --vpc-connector=${CONNECTOR_NAME} \
  --trigger-http \
  --allow-unauthenticated
```

