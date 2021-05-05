#!/bin/bash

CURRENTDIR=$(pwd)
artefactDir="$CURRENTDIR/.artefacts/"

if [ ! -d "$artefactDir/.jmx-common-scripts" ]; then
curl -sfL https://github.com/dmxunlimit/tools/raw/master/loadTestSuite/artefacts/jmx-common-scripts.tar -o $artefactDir/jmx-common-scripts.tar
tar -xf $artefactDir/jmx-common-scripts.tar -C $artefactDir/
mkdir -p $CURRENTDIR/jmx_scripts
cp -rf $artefactDir/jmx-common-scripts/* $CURRENTDIR/jmx_scripts
else
cp -rf $artefactDir/jmx-common-scripts/* $CURRENTDIR/jmx_scripts
fi

if [ -d "$CURRENTDIR/jmx_scripts" ]; then

hostname='localhost'
read -e -p "hostname/ip name [$hostname]: " input
hostname=${input:-$hostname}

port=9443
read -e -p "port [$port]: " input
port=${input:-$port}

adminuser='admin'
read -e -p "admin username [$adminuser]: " input
adminuser=${input:-$adminuser}

adminpass='admin'
read -e -p "admin password [$adminpass]: " input
adminpass=${input:-$adminpass}

NoUser=500
read -e -p "number of users [$NoUser]: " input
NoUser=${input:-$NoUser}

NoApps=200
read -e -p "number of apps [$NoApps]: " input
NoApps=${input:-$NoApps}

startCounter=1
read -e -p "start counter [$startCounter]: " input
startCounter=${input:-$startCounter}

concurrency=50
read -e -p "threads [$concurrency]: " input
concurrency=${input:-$concurrency}

timeToRunInMinutes=30
read -e -p "time to run in minutes [$timeToRunInMinutes]: " input
timeToRunInMinutes=${input:-$timeToRunInMinutes}

rampUpPeriod=10
read -e -p "ramp up time [$rampUpPeriod]: " input
rampUpPeriod=${input:-$rampUpPeriod}

timeToRun=$(( $timeToRunInMinutes * 60 ))

cred=$(echo -n $adminuser:$adminpass | base64)

##
sed  -e 's/hostname_val/'$hostname'/g' -i $CURRENTDIR/jmx_scripts/*

sed  -e 's/port_val/'$port'/g' -i $CURRENTDIR/jmx_scripts/*


##
sed  -e 's/userCount_val/'$NoUser'/g' -i $CURRENTDIR/jmx_scripts/*

sed  -e 's/sp_apps_val/'$NoApps'/g' -i $CURRENTDIR/jmx_scripts/*

sed  -e 's/startCounter_val/'$startCounter'/g' -i $CURRENTDIR/jmx_scripts/*


###
sed  -e 's/timeToRun_val/'$timeToRun'/g' -i $CURRENTDIR/jmx_scripts/*

sed  -e 's/concurrency_val/'$concurrency'/g' -i $CURRENTDIR/jmx_scripts/*

sed  -e 's/rampUpPeriod_val/'$rampUpPeriod'/g' -i $CURRENTDIR/jmx_scripts/*


##
sed  -e 's/base64AdminCred_val/'$cred'/g' -i $CURRENTDIR/jmx_scripts/*

sed  -e 's/admin_user_val/'$adminuser'/g' -i $CURRENTDIR/jmx_scripts/*

sed  -e 's/admin_password_val/'$adminpass'/g' -i $CURRENTDIR/jmx_scripts/*

echo "Common JMX scripts has generated in jmx_scripts !"
else
echo "Unable to get the base jmx scripts !"
fi

