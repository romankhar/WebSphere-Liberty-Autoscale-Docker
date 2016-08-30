#!/bin/bash

export JAVA_HOME=/opt/ibm.jdk.1.8/jre
export PATH=$PATH:$JAVA_HOME/bin
/opt/apache-jmeter-3.0/bin/jmeter.sh &