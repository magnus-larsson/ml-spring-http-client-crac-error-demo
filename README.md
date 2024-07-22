This branch of the project demonstrates how a RestTemplate bean can be used during warmup before creating a CRaC checkpoint using the `jcmd myapp.jar JDK.checkpoint` command.
Without a proper configuration, the RestTemplate bean will cause an error during the checkpoint operation. The error is related to open sockets that are not properly closed before the checkpoint is created.

> **Note:** See the main branch for how to reproduce the open socket error during CRaC checkpoint creation.

The project consists of a Spring Boot app that provides a HTTP endpoint which use a RestTemplate bean to send HTTP requests to `https://httpbin.org/uuid`. 

To try out the working solution in a Linux environment, clone the project from GitHub and run the test script `tests.bash`. The test script calls the endpoint during the warmup, i.e., before the `jcmd myapp.jar JDK.checkpoint` command is executed.
On Mac and Windows, a Docker container can be used as described below.

First ensure that a Java 21 JDK is used, e.g. by running a command like:

**On Linux**, use a Java 21 JDK with CRaC support:

```
sdk use java 21.0.2.crac-zulu
```

**On Windows or Mac**:

```
sdk use java 21.0.3-tem
```

Next, get the source code from GitHub and build:

```
git clone https://github.com/magnus-larsson/ml-spring-http-client-crac-error-demo.git
cd ml-spring-http-client-crac-error-demo
git checkout RestTemplateBuilder
./gradlew build
```

**On Linux**, run the following command to create a checkpoint after a warmup phase:

```
./tests.bash
```

**On Windows or Mac**, we need to run the tests in Docker since a Linux OS is required by CRaC.

Start a Linux container with the Azul JDK 21 CRaC, install `curl` and run the same test script to create a checkpoint after a warmup phase:

```
docker run -it --rm  -v ${PWD}:/demo --privileged --name demo azul/zulu-openjdk:21-jdk-crac bash

apt-get update
apt-get install curl -y

cd demo
./tests.bash
```

Now, the Spring Boot application can be restored from the checkpoint, and the endpoint can be called successfully. Run the following commands to verify:

**On Linux**, run the following commands:

```
java -XX:CRaCRestoreFrom=checkpoint
```

From another terminal, verify that the endpoints can be called successfully:

```
curl localhost:8080/actuator/health
curl localhost:8080/usingRestTemplate
```

**On Windows or Mac**, run the following commands using Docker:

In the docker session:
```
java -XX:CRaCRestoreFrom=checkpoint
```

From another terminal, jump into the running Docker container and verify that the endpoints can be called successfully:

```
docker exec -it demo bash

curl localhost:8080/actuator/health
curl localhost:8080/usingRestTemplate

exit
```
    
Finally, remove the Docker container:

```
docker rm -f demo
```
