#!/bin/sh

CURRENTDIR=$(pwd)
mkdir -p $CURRENTDIR/tools/

echo "Loading the script updates .."
curl -s https://raw.githubusercontent.com/dmxunlimit/tools/master/loadTestSuite/scripts/stop.sh -o stop.sh
sudo chmod 755 stop.sh

curl -s https://raw.githubusercontent.com/dmxunlimit/tools/master/loadTestSuite/scripts/loadtest.sh -o $CURRENTDIR/tools/loadtest.sh
sudo chmod 755 $CURRENTDIR/tools/loadtest.sh

pname=loadtest
process=$(ps aux | grep -v grep | grep $pname | awk '{print $2}')

if [ -z "$process" ]; then
  if [ -z "$1" ]; then
    echo "Provide the directory of the JMX files. \n"
    echo "Ex:"
    echo "./start.sh /home/jmxScripts"
    echo "\n*This also supports continues multi Directory/File execution based on the order of the Directory/file name"
    exit 1
  fi

  
  echo "Setting IST Time Zone !"
  sudo timedatectl set-timezone Asia/Colombo

  if [ ! -d "$CURRENTDIR/tools/jmeter" ]; then

    if [ ! -f $CURRENTDIR/tools/*jmeter* ]; then
      echo "\nDownloading Jmeter ..."
      wget https://downloads.apache.org//jmeter/binaries/apache-jmeter-5.4.1.tgz -q --show-progress -P $CURRENTDIR/tools/

    fi

    mkdir -p $CURRENTDIR/tools/temp
    tar -xvf $CURRENTDIR/tools/*jmeter* -C $CURRENTDIR/tools/temp
    mv $CURRENTDIR/tools/temp/* $CURRENTDIR/tools/jmeter
  fi

  if [ ! -n "$JAVA_HOME" ]; then
    if [ ! -d "$CURRENTDIR/tools/java" ]; then
      if [ ! -f $CURRENTDIR/tools/*jre* ]; then
        echo "\nDownloading JAVA ..."
        wget https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.10%2B9/OpenJDK11U-jre_x64_linux_hotspot_11.0.10_9.tar.gz -q --show-progress -P $CURRENTDIR/tools/
      fi

      mkdir -p $CURRENTDIR/tools/temp
      tar -xvf $CURRENTDIR/tools/*jre* -C $CURRENTDIR/tools/temp
      mv $CURRENTDIR/tools/temp/* $CURRENTDIR/tools/java
    fi
    export JAVA_HOME="$CURRENTDIR/tools/java"
    export PATH=$JAVA_HOME/bin:$PATH
    echo "JAVA_HOME Set to : $JAVA_HOME"
  else
    echo "Using Existing JAVA_HOME : $JAVA_HOME"
  fi

  rm -rf $CURRENTDIR/tools/temp

  sleep 1

  nohup bash $CURRENTDIR/tools/loadtest.sh $CURRENTDIR $1 &
  echo "\nBackgroud job created ./loadtest.sh !" && sleep 1 && tail -n 0 -f nohup.out

else
  printf "Already running process found for $pname \n"
  sudo ./stop.sh
fi
