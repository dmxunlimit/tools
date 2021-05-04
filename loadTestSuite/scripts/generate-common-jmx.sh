#!/bin/bash

CURRENTDIR=$(pwd)

if [ ! -d "$CURRENTDIR/tools/.jmx-common-scripts" ]; then
curl -s https://raw.githubusercontent.com/dmxunlimit/tools/master/loadTestSuite/scripts/.jmx-common-scripts.tar -o $CURRENTDIR/tools/.jmx-common-scripts.tar
tar -xf $CURRENTDIR/tools/.jmx-common-scripts.tar -C $CURRENTDIR/tools/ 
fi

mkdir -p jmx_scripts

cp -rf .jmx-common-scripts/* jmx_scripts

hostname='localhost'
port=9443
adminuser='admin'
adminpass='admin'

NoUser=1000
NoApps=200
startCounter=1

concurrency=50
timeToRunInMinutes=30
rampUpPeriod=10

timeToRun=$(( $timeToRunInMinutes * 60 ))

cred=$(echo -n $adminuser:$adminpass | base64)

##
sed -i '' -e 's/hostname_val/'$hostname'/g' jmx_scripts/*

sed -i '' -e 's/port_val/'$port'/g' jmx_scripts/*


##
sed -i '' -e 's/userCount_val/'$NoUser'/g' jmx_scripts/*

sed -i '' -e 's/sp_apps_val/'$NoApps'/g' jmx_scripts/*

sed -i '' -e 's/startCounter_val/'$startCounter'/g' jmx_scripts/*


###
sed -i '' -e 's/timeToRun_val/'$timeToRun'/g' jmx_scripts/*

sed -i '' -e 's/concurrency_val/'$concurrency'/g' jmx_scripts/*

sed -i '' -e 's/rampUpPeriod_val/'$rampUpPeriod'/g' jmx_scripts/*


##
sed -i '' -e 's/base64AdminCred_val/'$cred'/g' jmx_scripts/*

sed -i '' -e 's/admin_user_val/'$adminuser'/g' jmx_scripts/*

sed -i '' -e 's/admin_password_val/'$adminpass'/g' jmx_scripts/*


