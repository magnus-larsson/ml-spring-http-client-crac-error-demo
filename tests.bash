#!/usr/bin/env bash

set -e
set -x

function testCurlCmd() {
  if $@; then return 0; else return 1; fi
}

function waitForService() {
  url="curl $@ -ks -f -o /dev/null"
  echo -n "Wait for: $url... "
  sleep 3
  n=0
  until testCurlCmd $url; do
    n=$((n + 1))
    if [[ $n == 100 ]]; then
      echo "Give up"
      exit 1
    else
      sleep 3
      echo "Retry #$n "
    fi
  done
  echo "DONE, continues..."
}

./gradlew build
rm -rf checkpoint
java -XX:CRaCCheckpointTo=checkpoint -jar build/libs/demo-0.0.1-SNAPSHOT.jar &

waitForService localhost:8080/actuator
curl localhost:8080/usingRestTemplate
curl localhost:8080/usingRestClient
curl localhost:8080/usingWebClient

jcmd build/libs/demo-0.0.1-SNAPSHOT.jar JDK.checkpoint

