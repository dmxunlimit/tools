#!/bin/sh

# Detect the platform (similar to $OSTYPE)
OS="$(uname)"
case $OS in
'Linux')
  echo "Setting IST Time Zone !"
  sudo timedatectl set-timezone Asia/Colombo
  ;;

esac

##### Automated script update #####

script_dir=$(dirname "$0")
scriptBaseName="$(basename $0)"
scriptFile="$script_dir/$scriptBaseName"
scriptFilelst=$scriptFile"_latest"
echo "Checking for latest version of the script $scriptBaseName !"

curl -sf https://raw.githubusercontent.com/dmxunlimit/tools/master/loadTestSuite/$scriptBaseName -o $scriptFilelst

if [ -f "$scriptFilelst" ] && [ -s "$scriptFilelst" ]; then

  case $OS in
  'Linux')
    alias ls='ls --color=auto'
    crr_md5=$(md5sum $scriptFile)
    remt_md5=$(md5sum $scriptFilelst)
    crr_md5=$(echo $crr_md5 | cut -d " " -f1)
    remt_md5=$(echo $remt_md5 | cut -d " " -f1)
    ;;
  'Darwin')
    crr_md5=$(md5 $scriptFile)
    remt_md5=$(md5 $scriptFilelst)
    crr_md5=$(echo $crr_md5 | cut -d "=" -f2)
    remt_md5=$(echo $remt_md5 | cut -d "=" -f2)
    ;;
  *)
    crr_md5=$(md5sum $scriptFile)
    remt_md5=$(md5sum $scriptFilelst)
    crr_md5=$(echo $crr_md5 | cut -d " " -f1)
    remt_md5=$(echo $remt_md5 | cut -d " " -f1)
    ;;
  esac

  if [ "$crr_md5" != "$remt_md5" ]; then
    printf "\nUpdate found for the script, hence updating."
    mv $scriptFilelst $scriptFile
    chmod 755 $scriptFile
    printf "\nPlease run it again !!\n"
    exit
  else
    rm -rf $scriptFilelst
  fi
fi

####

CURRENTDIR=$(pwd)
mkdir -p $CURRENTDIR/.artefacts/
artefactDir="$CURRENTDIR/.artefacts/"

echo "Loading the script updates .."
curl -sf https://raw.githubusercontent.com/dmxunlimit/tools/master/loadTestSuite/artefacts/stop.sh -o stop.sh
sudo chmod 755 stop.sh

curl -sf https://raw.githubusercontent.com/dmxunlimit/tools/master/loadTestSuite/artefacts/loadtest.sh -o $artefactDir/loadtest.sh
sudo chmod 755 $artefactDir/loadtest.sh

curl -sf https://raw.githubusercontent.com/dmxunlimit/tools/master/loadTestSuite/artefacts/generate-common-jmx.sh -o generate-scritps.sh
sudo chmod 755 $CURRENTDIR/generate-scritps.sh

pname=loadtest.sh
process=$(ps aux | grep -v grep | grep $pname | awk '{print $2}')

if [ -z "$process" ]; then
  if [ -z "$1" ]; then
    echo "Provide the directory of the JMX files. \n"
    echo "Ex:"
    echo "./loadtest-runner.sh jmxScripts"
    echo "\n*This also supports continues multi Directory/File execution based on the order of the Directory/file name"
    exit 1
  fi

  if [ ! -d "$artefactDir/jmeter" ]; then

    if [ ! -f $artefactDir/*jmeter* ]; then
      echo "\nDownloading Jmeter ..."
      wget https://downloads.apache.org/jmeter/binaries/apache-jmeter-5.4.1.tgz -q --show-progress -P $artefactDir/

    fi

    mkdir -p $artefactDir/temp
    tar -xf $artefactDir/*jmeter* -C $artefactDir/temp
    mv $artefactDir/temp/* $artefactDir/jmeter
  fi

  if [ ! -n "$JAVA_HOME" ]; then
    if [ ! -d "$artefactDir/java" ]; then
      if [ ! -f $artefactDir/*jre* ]; then
        echo "\nDownloading JAVA ..."
        wget https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.10%2B9/OpenJDK11U-jre_x64_linux_hotspot_11.0.10_9.tar.gz -q --show-progress -P $artefactDir/
      fi

      mkdir -p $artefactDir/temp
      tar -xf $artefactDir/*jre* -C $artefactDir/temp
      mv $artefactDir/temp/* $artefactDir/java
    fi

    echo -e "\nexport JAVA_HOME='$artefactDir/java' \nexport PATH=\$PATH:\$JAVA_HOME/bin" >>~/.bashrc && source ~/.bashrc

    echo "JAVA_HOME Set to : $JAVA_HOME"
  else
    echo "Using Existing JAVA_HOME : $JAVA_HOME"
  fi

  rm -rf $artefactDir/temp

  sleep 1

  echo -e "\n" >>nohup.out
  nohup bash $artefactDir/loadtest.sh $CURRENTDIR $1 &
  echo "\nBackgroud job created ./loadtest.sh !" && tail -n 0 -f nohup.out

else
  printf "Already running process found for $pname \n"
  sudo ./stop.sh
fi
