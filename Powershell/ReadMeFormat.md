# Dataflow Streaming Benchmark

During Dataflow pipelines development, common requirement is to run a benchmark at a specific QPS using
fake or generated data. This pipeline takes in a QPS parameter, a path to a schema file, and 
generates fake JSON messages matching the schema to a Pub/Sub topic at the QPS rate.

## Pipeline

[StreamingBenchmark](src/main/java/com/google/cloud/teleport/v2/templates/StreamingBenchmark.java) -
A streaming pipeline which generates messages at a specified rate to a Pub/Sub topic. The messages 
are generated according to a schema template and instructs the pipeline to populate the 
messages with fake data compliant to constraints.

> Note the number of workers executing the pipeline must be large enough to support the supplied 
> QPS. Use a general rule of 2,500 QPS per core in the worker pool when configuring your pipeline.

## Getting Started

### Requirements

* Java 8
* Maven 3
* PubSub Topic

### Creating the Schema File
The schema file used to generate JSON messages with fake data  based on the 
[json-data-generator](https://github.com/vincentrussell/json-data-generator) library. This library
allows for the structuring of a sample JSON schema and injection of common faker functions to 
instruct the data generator of what type of fake data to create in each field. See the 
json-data-generator [docs](https://github.com/vincentrussell/json-data-generator) for more 
information on the faker functions.

#### Example Schema File
Below is an example schema file which generates fake game event payloads with random data.

```javascript
{
  "eventId": "{{uuid()}}",
  "eventTimestamp": {{timestamp()}},
  "ipv4": "{{ipv4()}}",
  "ipv6": "{{ipv6()}}",
  "country": "{{country()}}",
  "username": "{{username()}}",
  "quest": "{{random("A Break In the Ice", "Ghosts of Perdition", "Survive the Low Road")}}",
  "score": {{integer(100, 10000)}},
  "completed": {{bool()}}
}
```
*Note*: Additional options such as max workers, service account can be specified in the parameters section as shown below:
  
 ```sh
  --parameters autoscalingAlgorithm="THROUGHPUT_BASED",schemaLocation=$SCHEMA_LOCATION,topic=$PUBSUB_TOPIC,qps=$QPS,maxNumWorkers=5,serviceAccount=$serviceAccount
```
