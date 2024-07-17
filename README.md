This project can reproduce problems by using RestTemplate and RestClient during warmup before creating a CRaC checkpoint using the `jcmd myapp.jar JDK.checkpoint` command.

The project consists of a Spring Boot app that provides three HTTP endpoints. These endpoints use a RestTemplate, RestClient, and WebClient bean to send HTTP requests to `https://httpbin.org/uuid`. 

To reproduce the problem in a Linux environment, clone the project from GitHub and run the test script `tests.bash`. The test script calls all three endpoints during the warmup, i.e., before the `jcmd myapp.jar JDK.checkpoint` command is executed.

First ensure that a Java 21 JDK is used, e.g. by running a command like:

**On Linux**, use a Java 21 JDK with CRaC support:

```
sdk use java 21.0.2.crac-zulu
```

**On Windows or Mac**:

```
sdk use java 21.0.3.tem
```

Next, get the source code from GitHub and build:

```
git clone https://github.com/magnus-larsson/ml-spring-http-client-crac-error-demo.git
cd ml-spring-http-client-crac-error-demo
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
An exception during a checkpoint operation:
jdk.internal.crac.mirror.CheckpointException
	Suppressed: java.nio.channels.IllegalSelectorException
		at java.base/sun.nio.ch.EPollSelectorImpl.beforeCheckpoint(EPollSelectorImpl.java:401)
		at java.base/jdk.internal.crac.mirror.impl.AbstractContext.invokeBeforeCheckpoint(AbstractContext.java:43)
		at java.base/jdk.internal.crac.mirror.impl.AbstractContext.beforeCheckpoint(AbstractContext.java:58)
		at java.base/jdk.internal.crac.mirror.impl.BlockingOrderedContext.beforeCheckpoint(BlockingOrderedContext.java:64)
		at java.base/jdk.internal.crac.mirror.impl.AbstractContext.invokeBeforeCheckpoint(AbstractContext.java:43)
		at java.base/jdk.internal.crac.mirror.impl.AbstractContext.beforeCheckpoint(AbstractContext.java:58)
		at java.base/jdk.internal.crac.mirror.Core.checkpointRestore1(Core.java:153)
		at java.base/jdk.internal.crac.mirror.Core.checkpointRestore(Core.java:286)
		at java.base/jdk.internal.crac.mirror.Core.checkpointRestoreInternal(Core.java:299)
	Suppressed: jdk.internal.crac.mirror.impl.CheckpointOpenSocketException: java.nio.channels.SocketChannel[connected local=/10.211.55.4:50404 remote=httpbin.org/18.214.17.35:443]
		at java.base/jdk.internal.crac.JDKSocketResourceBase.lambda$beforeCheckpoint$0(JDKSocketResourceBase.java:68)
		at java.base/jdk.internal.crac.mirror.Core.checkpointRestore1(Core.java:169)
		at java.base/jdk.internal.crac.mirror.Core.checkpointRestore(Core.java:286)
		at java.base/jdk.internal.crac.mirror.Core.checkpointRestoreInternal(Core.java:299)
	Suppressed: jdk.internal.crac.mirror.impl.CheckpointOpenSocketException: Socket[addr=httpbin.org/18.214.17.35,port=443,localport=50394]
		at java.base/jdk.internal.crac.JDKSocketResourceBase.lambda$beforeCheckpoint$0(JDKSocketResourceBase.java:68)
		at java.base/jdk.internal.crac.mirror.Core.checkpointRestore1(Core.java:169)
		at java.base/jdk.internal.crac.mirror.Core.checkpointRestore(Core.java:286)
		at java.base/jdk.internal.crac.mirror.Core.checkpointRestoreInternal(Core.java:299)
	Suppressed: jdk.internal.crac.mirror.impl.CheckpointOpenResourceException: FD fd=9 type=unknown path=anon_inode:[eventpoll]
		at java.base/jdk.internal.crac.mirror.Core.translateJVMExceptions(Core.java:117)
		at java.base/jdk.internal.crac.mirror.Core.checkpointRestore1(Core.java:188)
		at java.base/jdk.internal.crac.mirror.Core.checkpointRestore(Core.java:286)
		at java.base/jdk.internal.crac.mirror.Core.checkpointRestoreInternal(Core.java:299)
	Suppressed: jdk.internal.crac.mirror.impl.CheckpointOpenResourceException: FD fd=10 type=unknown path=anon_inode:[eventfd]
		at java.base/jdk.internal.crac.mirror.Core.translateJVMExceptions(Core.java:117)
		at java.base/jdk.internal.crac.mirror.Core.checkpointRestore1(Core.java:188)
		at java.base/jdk.internal.crac.mirror.Core.checkpointRestore(Core.java:286)
		at java.base/jdk.internal.crac.mirror.Core.checkpointRestoreInternal(Core.java:299)
```

To avoid these errors, remove the following calls to the RestTemplate and RestClient endpoints in `tests.bash`:

```
curl localhost:8080/usingRestTemplate
curl localhost:8080/usingRestClient
```

> **Note:** The WebClient endpoint can still be used during the warmup.

Now, rerun the test script to create a checkpoint. The Spring Boot application can be restored from the checkpoint, and the endpoints can be called successfully. Run the following commands to verify:

**On Linux**, run the follwoing commands:

```
./tests.bash

java -XX:CRaCRestoreFrom=checkpoint

curl localhost:8080/actuator/health
curl localhost:8080/usingRestTemplate
curl localhost:8080/usingRestClient
curl localhost:8080/usingWebClient
```

**On Windows or Mac**, run the following commands using Docker:

In the docker session:
```
./tests.bash

java -XX:CRaCRestoreFrom=checkpoint
```

From another terminal, jump into the running Docker container and verify that the endpoints can be called successfully:

```
docker exec -it demo bash

curl localhost:8080/actuator/health
curl localhost:8080/usingRestTemplate
curl localhost:8080/usingRestClient
curl localhost:8080/usingWebClient

exit
```
    
Finally, remove the Docker container:

```
docker rm -f demo
```
