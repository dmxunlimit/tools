#!/bin/bash

# Detect the platform (similar to $OSTYPE)
OS="$(uname)"
case $OS in
'Linux')
  echo "Setting IST Time Zone !"
  sudo timedatectl set-timezone Asia/Colombo
  ;;

esac

## Colors
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'

##### Automated script update #####

script_dir="$(
  cd "$(dirname "$0")"
  pwd
)"
scriptBaseName="$(basename $0)"
scriptFile="$script_dir/$scriptBaseName"
scriptFilelst="."$scriptBaseName"_latest"
scriptFilelst=$script_dir"/"$scriptFilelst
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
    printf "\n${blu}NEW UPDATE FOUND !\n${end}"
    read -p 'Do you wish to update the script [no]: ' updateScript
    updateScript=$(echo "$updateScript" | awk '{print tolower($0)}')
    if [ "$updateScript" == "yes" ] || [ "$updateScript" == "y" ]; then
      printf "\nUpdating The Script File "
      mv $scriptFilelst $scriptFile
      chmod 755 $scriptFile
      printf "\n\n${red}Please Run The Script Again !!${end}\n\n"
      exit
    fi

  else
    rm -rf $scriptFilelst
  fi
fi

####

artefactDir="$script_dir/artefacts"

curl -sfL https://github.com/dmxunlimit/tools/raw/master/loadTestSuite/.artefacts.tar -o $script_dir/.artefacts.tar

if [ -f $script_dir/.artefacts.tar ]; then
  mkdir -p $artefactDir
  tar -xf $script_dir/.artefacts.tar -C $script_dir
  cp -f $artefactDir/stop.sh stop.sh
fi

pname=loadtest.sh
process=$(ps aux | grep -v grep | grep $pname | awk '{print $2}')
jmxFiles=$1

if [ -z "$jmxFiles" ]; then
  echo ""
  read -p 'Do you wish to generate new jmx scripts [no]: ' genScripts
  genScripts=$(echo "$genScripts" | awk '{print tolower($0)}')
  if [ "$genScripts" == "yes" ] || [ "$genScripts" == "y" ]; then
    printf "\nGenerating jmx script files !\n"
    sh $artefactDir/generate-common-jmx.sh $script_dir $artefactDir

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
fi
if [ -z "$process" ]; then

  if [ -z "$jmxFiles" ]; then
    printf "\n\n${red}Provide the directory of the JMX files.${end} \n"
    echo "Ex:"
    echo "./loadtest-runner.sh jmx_scripts"
    printf "\n** This also supports continues multi Directory/File execution based on the order of the Directory/file names\n"
    printf "ex:\njmx_scripts\n  |- 1_script.jmx\n  |- 2_script.jmx\n  |- 1_Directory\n  |     |- 1_D1_script.jmx\n  |- 2_Directory\n        |- 1_D2_script.jmx\n\n"
    exit 1
  fi

  if [ ! -d "$artefactDir/jmeter" ]; then
    printf "Downloading Jmeter ...\n"
    rm -rf $artefactDir/*jmeter*
    wget https://downloads.apache.org/jmeter/binaries/apache-jmeter-5.4.1.tgz -q --show-progress -P $artefactDir/
    mkdir -p $artefactDir/temp
    tar -xf $artefactDir/*jmeter* -C $artefactDir/temp
    mv $artefactDir/temp/* $artefactDir/jmeter
  fi

  if [ ! -n "$JAVA_HOME" ]; then
    if [ $OS == "Linux" ]; then
      if [ ! -d "$artefactDir/java" ]; then

        printf "\nDownloading JAVA ...\n"
        rm -rf $artefactDir/*jre*
        wget https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.10%2B9/OpenJDK11U-jre_x64_linux_hotspot_11.0.10_9.tar.gz -q --show-progress -P $artefactDir/

        mkdir -p $artefactDir/temp
        tar -xf $artefactDir/*jre* -C $artefactDir/temp
        mv $artefactDir/temp/* $artefactDir/java
      fi

      isJavaAlredySet=$(grep -ir "JAVA_HOME" ~/.bashrc | grep -v "#" -c)
      if [ "$isJavaAlredySet" == "0" ]; then
        printf "\nexport JAVA_HOME='$artefactDir/java' \nexport PATH=\$PATH:\$JAVA_HOME/bin" >>~/.bashrc
      fi

      javaSetInPath=$(echo $PATH | grep java -c)
      if [ "$javaSetInPath" == "0" ]; then
        export PATH=$PATH:$JAVA_HOME/bin
      fi
      export JAVA_HOME=$artefactDir/java

      echo "JAVA_HOME Set to : $JAVA_HOME"
    else
      printf "\n${red}JAVA_HOME is not available !!${end}\n"
      exit
    fi
  else
    printf "\nUsing Existing JAVA_HOME : $JAVA_HOME \n"
  fi

  rm -rf $artefactDir/temp

  sleep 1

  echo -e "\n" >>nohup.out
  nohup sh $artefactDir/loadtest.sh $script_dir $jmxFiles &
  printf "\nBackgroud job created ./loadtest.sh !\n" && tail -0f nohup.out

else
  printf "Already running process found for $pname \n"
  sudo ./stop.sh
fi
