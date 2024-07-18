#!/usr/bin/env bash

set -e
# set -x

function testCurlCmd() {
  if $@; then return 0; else return 1; fi
}

function waitForService() {
  local url="curl $@ -ks -f -o /dev/null"
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

function killJavaAppIfCheckpointFailed () {

  # Give the checkpoint a chance to complete...
  sleep 3

  local pid=$(jcmd | grep demo-0.0.1-SNAPSHOT.jar | awk '{print $1}')

  if [ "$pid" != "" ]; then
    echo "Shutting down the Java app with PID $pid after a failed CRaC checkpoint"
    kill -9 $pid
  else
    echo "No Java app found to shut down, CRaC checkpoint was successful"
  fi
}

cd $(dirname $0)
rm -rf checkpoint

java -XX:CRaCCheckpointTo=checkpoint -jar build/libs/demo-0.0.1-SNAPSHOT.jar &

waitForService localhost:8080/actuator/health
curl localhost:8080/usingRestTemplate

jcmd build/libs/demo-0.0.1-SNAPSHOT.jar JDK.checkpoint
killJavaAppIfCheckpointFailed
