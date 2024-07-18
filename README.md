This project can reproduce problems by using RestTemplate and RestClient during warmup before creating a CRaC checkpoint using the `jcmd myapp.jar JDK.checkpoint` command.

The project consists of a Spring Boot app that provides one HTTP endpoint. This endpoint use a RestTemplate to send HTTP requests to `https://httpbin.org/uuid`. 

To reproduce the problem in a Linux environment, clone the project from GitHub and run the test script `tests.bash`. The test script calls the endpoint during the warmup, i.e., before the `jcmd myapp.jar JDK.checkpoint` command is executed.
On Mac and Windows, a Docker container can be used to reporduce the problem as described below.

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

**On Linux**, run the following command to reproduce the problem:

```
./tests.bash
```

**On Windows or Mac**, we need to run the tests in Docker since a Linux OS is required by CRaC.

Start a Linux container with the Azul JDK 21 CRaC, install `curl` and run the same test script to reproduce the problem:

```
docker run -it --rm  -v ${PWD}:/demo --privileged --name demo azul/zulu-openjdk:21-jdk-crac bash

apt-get update
apt-get install curl -y

cd demo
./tests.bash
```

This will result in open socket related errors like:

```
2024-07-18T07:42:49.636Z  INFO 2789 --- [Attach Listener] jdk.crac                                 : Starting checkpoint
2024-07-18T07:42:49.692Z  INFO 2789 --- [Attach Listener] o.s.c.support.DefaultLifecycleProcessor  : Restarting Spring-managed lifecycle beans after JVM restore
2024-07-18T07:42:49.693Z  INFO 2789 --- [Attach Listener] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 8080 (http) with context path '/'
2024-07-18T07:42:49.694Z  INFO 2789 --- [Attach Listener] o.s.c.support.DefaultLifecycleProcessor  : Spring-managed lifecycle restart completed (restored JVM running for -1 ms)
An exception during a checkpoint operation:
jdk.internal.crac.mirror.CheckpointException
	Suppressed: jdk.internal.crac.mirror.impl.CheckpointOpenSocketException: Socket[addr=httpbin.org/52.207.37.75,port=443,localport=37062]
		at java.base/jdk.internal.crac.JDKSocketResourceBase.lambda$beforeCheckpoint$0(JDKSocketResourceBase.java:68)
		at java.base/jdk.internal.crac.mirror.Core.checkpointRestore1(Core.java:169)
		at java.base/jdk.internal.crac.mirror.Core.checkpointRestore(Core.java:294)
		at java.base/jdk.internal.crac.mirror.Core.checkpointRestoreInternal(Core.java:307)
```

To avoid this error, remove the following call to the RestTemplate endpoint in `tests.bash`:

```
curl localhost:8080/usingRestTemplate
```

Now, rerun the test script to create a checkpoint. The Spring Boot application can be restored from the checkpoint, and the endpoint can be called successfully. Run the following commands to verify:

**On Linux**, run the follwoing commands:

```
./tests.bash

java -XX:CRaCRestoreFrom=checkpoint

curl localhost:8080/actuator/health
curl localhost:8080/usingRestTemplate
```

**On Windows or Mac**, run the following commands using Docker:

In the docker session:
```
./tests.bash

java -XX:CRaCRestoreFrom=checkpoint
```

From another terminal, jump into the running Docker container and verify that the endpoint can be called successfully:

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
