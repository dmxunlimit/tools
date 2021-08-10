#!/bin/bash

# tar -cvf .artefacts.tar .artefacts/*
# Detect the platform (similar to $OSTYPE)
OS="$(uname)"
case $OS in
'Linux')
  echo "Setting IST Time Zone !"
  sudo timedatectl set-timezone Asia/Colombo
  ;;

esac

##### Automated script update #####

script_dir="$(
  cd "$(dirname "$0")"
  pwd
)"
scriptBaseName="$(basename $0)"
scriptFile="$script_dir/$scriptBaseName"
scriptFilelst=$script_dir$scriptBaseName"_latest"
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
    read -p 'NEW UPDATE FOUND ! Do you wish to update the script [no]: ' updateScript
    updateScript=$(echo "$updateScript" | awk '{print tolower($0)}')
    if [ "$updateScript" == "yes" ] || [ "$updateScript" == "y" ]; then
      printf "\nUpdating the script file .."
      mv $scriptFilelst $scriptFile
      chmod 755 $scriptFile
      printf "\nPlease run it again !!\n"
      exit
    fi

  else
    rm -rf $scriptFilelst
  fi
fi

curl -sfL https://github.com/dmxunlimit/tools/raw/master/loadTestSuite/.artefacts.tar -o $script_dir/.artefacts.tar

if [ -f $script_dir/.artefacts.tar ]; then
  mkdir -p $script_dir/.artefacts
  tar -xf $script_dir/.artefacts.tar -C $script_dir
  cp -f $script_dir/.artefacts/stop.sh stop.sh
fi

####

artefactDir="$script_dir/.artefacts"

pname=loadtest.sh
process=$(ps aux | grep -v grep | grep $pname | awk '{print $2}')
jmxFiles=$1

echo ""
read -p 'Do you wish to generate new jmx scripts [no]: ' genScripts
genScripts=$(echo "$genScripts" | awk '{print tolower($0)}')
if [ "$genScripts" == "yes" ] || [ "$genScripts" == "y" ]; then
  printf "\nGenerating jmx script files !\n"
  sh $artefactDir/generate-common-jmx.sh

  echo ""
  genScriptsCon='yes'
  read -p 'Do you wish to continue running loadtest with the generated JMX files [yes]: ' input
  genScriptsCon=${input:-$genScriptsCon}
  genScriptsCon=$(echo "$genScriptsCon" | awk '{print tolower($0)}')

  if [ "$genScriptsCon" == "yes" ] || [ "$genScriptsCon" == "y" ]; then
    jmxFiles=$script_dir/jmx_scripts
  else
    exit
  fi
fi

if [ -z "$process" ]; then

  if [ -z "$jmxFiles" ]; then
    printf "Provide the directory of the JMX files. \n"
    echo "Ex:"
    echo "./loadtest-runner.sh jmxScripts"
    printf "*This also supports continues multi Directory/File execution based on the order of the Directory/file names\n\n"
    exit 1
  fi

  if [ ! -d "$artefactDir/jmeter" ]; then
    if [ ! -f $artefactDir/*jmeter* ]; then
      printf "\nDownloading Jmeter ..."
      wget https://downloads.apache.org/jmeter/binaries/apache-jmeter-5.4.1.tgz -q --show-progress -P $artefactDir/
    fi
    mkdir -p $artefactDir/temp
    tar -xf $artefactDir/*jmeter* -C $artefactDir/temp
    mv $artefactDir/temp/* $artefactDir/jmeter
  fi

  if [ ! -n "$JAVA_HOME" ]; then
    if [ ! -d "$artefactDir/java" ]; then
      if [ ! -f $artefactDir/*jre* ]; then
        printf "\nDownloading JAVA ..."
        wget https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.10%2B9/OpenJDK11U-jre_x64_linux_hotspot_11.0.10_9.tar.gz -q --show-progress -P $artefactDir/
      fi

      mkdir -p $artefactDir/temp
      tar -xf $artefactDir/*jre* -C $artefactDir/temp
      mv $artefactDir/temp/* $artefactDir/java
    fi

    printf "\nexport JAVA_HOME='$artefactDir/java' \nexport PATH=\$PATH:\$JAVA_HOME/bin" >>~/.bashrc && source ~/.bashrc

    echo "JAVA_HOME Set to : $JAVA_HOME"
  else
    echo "Using Existing JAVA_HOME : $JAVA_HOME"
  fi

  rm -rf $artefactDir/temp

  sleep 1

  echo -e "\n" >>nohup.out
  nohup sh $artefactDir/loadtest.sh $script_dir $jmxFiles &
  printf "\nBackgroud job created ./loadtest.sh !" && tail -0f nohup.out

else
  printf "Already running process found for $pname \n"
  sudo ./stop.sh
fi
