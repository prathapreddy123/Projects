# Teleport Integration Test Setup for Pub/Sub to MongoDB

The Pub/Sub to MongoDB Dataflow pipeline integration test has following system requirements:

 * Standalone MongoDB instance to be used as a pipeline sink
 * Cloud function to verify the Integration test result
 
This repository contains the scripts/steps needed to setup the standalone test instance as well as deploy cloud function.

Note that the same test instance is used by all the integration tests (staging, head, prod, release). 
The integration test will need to create unique records to distinguish between its messages.

### Prerequisites ###
* GKE Cluster must be set up and running. 

#### Deploy Splunk HEC standalone instance ####

1. Create a GCE instance to host the Splunk HEC endpoint. This process has been terraformed for convenience.

```shell
PROJECT=cloud-teleport-testing
cd terraform
$ terraform plan -var gcp_project_name=${PROJECT}
$ terraform apply -var gcp_project_name=${PROJECT} -auto-approve
```

2. Push setup-splunk.sh to the GCE instance.

```shell
PROJECT=cloud-teleport-testing
gcloud compute scp setup-splunk.sh nokill-pubsub-to-splunk-integration-test:/tmp/ --zone=us-central1-b --project=${PROJECT}
```

3. Execute splunk-setup.sh on the GCE instance

```shell
PROJECT=cloud-teleport-testing
gcloud compute ssh nokill-pubsub-to-splunk-integration-test --zone=us-central1-b --project=${PROJECT}
cd /tmp
sudo ./setup-splunk.sh
```

4. Confirm Splunkd is running

```shell
sudo systemctl status Splunkd
```
