# nexus-iq-sbt
Simplified Nexus IQ policy evaluator for Scala/sbt projects

## Generating local image
Clone this project in to your local machine and run the following 
```shell
docker build --build-arg OPENJDK_TAG=11.0.13 --build-arg SBT_VERSION=1.6.2 --tag sonatype/nexus-iq-sbt:1.0.0 --tag sonatype/nexus-iq-sbt:latest .
```

## Running
if you want the container to communicate with your IQ server running locally (container host), you must create a local docker network. 
For example
```shell
docker network create -d bridge --subnet 192.168.0.0/24 --gateway 192.168.0.1 dockernet
```

The container can now access the host machine using 192.168.0.1 IP address. Here is a complete example of how the evaluation call (assuming your local IQ server has an application named scala-app)
```shell
docker run -it --net=dockernet  sonatype/nexus-iq-sbt /app/nexus-iq-sbt.sh  -projectUrl https://github.com/Kambius/simple-app.git -applicationId simple-app -username admin -password admin123 -stage build
```

Note: the script uses default IQ username (admin), password (admin123) and stage (build) and if your local setup uses the same you can avoid passing them to the script   
