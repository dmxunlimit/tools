#!/bin/sh

CreateStopScript() {
sudo echo '#!/bin/sh
pname=loadtest
process=$(ps aux | grep -v grep | grep $pname | awk '\''{print $2}'\'')
jprocess=$(ps aux | grep -v grep | grep jmeter | awk '\''{print $2}'\'')

if [ -z "$process" ]; then
  printf "No running process for $pname \n"
else
  echo $(ps aux | grep -v grep | grep $pname)
  printf '\''\n'\''
  read -p "Do you wish to kill the service y/n :" killme
  if [ "$killme" = "y" ]; then
    sudo kill -9 $process
    if [ -z "$jprocess" ]; then
    sudo kill -9 $jprocess
    fi
    sleep 3

    printf "\nVerify the running process for $pname \n"

    process=$(ps aux | grep -v grep | grep $pname | awk "{print $2}")
    if [ -z "$process" ]; then
      printf "Yey, Successfully stop the $pname ! \n"
    else
      echo $(ps aux | grep -v grep | grep $pname)
      printf '\''\n'\''
    fi
  fi
fi' >stop.sh
  sudo chmod 755 stop.sh
}

CreateLoadTestScript() {
sudo echo '#!/bin/bash
newFiles=1

while [ $newFiles == 1 ]; do

    if [ $(find $2 -name "*.jmx" | wc -l) -gt 0 ]; then
        newFiles=1
        echo "New JMX scripts are available to Process !"
    else
        echo "No JMX scripts are available to Process !, Hence Shutting down ..."
        break
    fi

    for f in $(find $2 -name '*.jmx' | sort -n); do

        FILE=$f
        echo " "
        echo " "

        echo "Processing File : $FILE"

        basename "$FILE"
        JOB="$(basename -- $FILE)"
        JOB=${JOB%%.*}

        RESULTFILE="$JOB.results"
        echo "Result File : $RESULTFILE"

        current_time=$(date "+%Y-%m-%d:%H-%M-%S")
        echo "Current Time : $current_time"
        WRKDIR=$1
        echo "Working Dir : $WRKDIR"

        RESULTDIR="$WRKDIR/results/$JOB"_"$current_time"
        mkdir -p $RESULTDIR
        echo "Result Dir : $RESULTDIR"

        sleep 1

        sh $WRKDIR/tools/jmeter/bin/jmeter -n -t $FILE -l $RESULTDIR/$RESULTFILE -e -o $RESULTDIR

        cp $FILE $RESULTDIR
        rm -rf $FILE

        echo "Sleeping for 5 seconds ..."
        sleep 5

    done

done
' >$CURRENTDIR/tools/loadtest.sh
  sudo chmod 755 $CURRENTDIR/tools/loadtest.sh
}

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

  CURRENTDIR=$(pwd)

  echo "Setting IST Time Zone !"
  sudo timedatectl set-timezone Asia/Colombo

  if [ ! -d "$CURRENTDIR/tools/jmeter" ]; then

    if [ ! -f $CURRENTDIR/tools/*jmeter* ]; then
      wget https://downloads.apache.org//jmeter/binaries/apache-jmeter-5.4.1.tgz -P $CURRENTDIR/tools/
    fi

    mkdir -p $CURRENTDIR/tools/temp
    tar -xvf $CURRENTDIR/tools/*jmeter* -C $CURRENTDIR/tools/temp
    mv $CURRENTDIR/tools/temp/* $CURRENTDIR/tools/jmeter
  fi

  if [ ! -n "$JAVA_HOME" ]; then
    if [ ! -d "$CURRENTDIR/tools/java" ]; then
      if [ ! -f $CURRENTDIR/tools/*jre* ]; then
        wget https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.10%2B9/OpenJDK11U-jre_x64_linux_hotspot_11.0.10_9.tar.gz -P $CURRENTDIR/tools/
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

  CreateLoadTestScript
  CreateStopScript

  sleep 1

  nohup bash $CURRENTDIR/tools/loadtest.sh $CURRENTDIR $1 &
  echo "\nBackgroud job created ./loadtest.sh !" && sleep 1 && tail -n 0 -f nohup.out

else
  CreateStopScript
  printf "Already running process found for $pname \n"
  sudo ./stop.sh
fi
