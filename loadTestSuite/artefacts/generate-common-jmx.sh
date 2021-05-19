#!/bin/bash

CURRENTDIR=$(pwd)
artefactDir="$CURRENTDIR/.artefacts/"

rm -rf $artefactDir/jmx-common-scripts
curl -sfL https://github.com/dmxunlimit/tools/raw/master/loadTestSuite/artefacts/jmx-common-scripts.tar -o $artefactDir/jmx-common-scripts.tar
tar -xf $artefactDir/jmx-common-scripts.tar -C $artefactDir/
mkdir -p $CURRENTDIR/jmx_scripts
cp -rf $artefactDir/jmx-common-scripts/* $CURRENTDIR/jmx_scripts

JmxUpdate() {

    key=$1
    value=$2

    sed -i.bkp 's/'$key'/'$value'/g' $CURRENTDIR/jmx_scripts/*

    rm -rf $CURRENTDIR/jmx_scripts/*.bkp

}

if [ -d "$CURRENTDIR/jmx_scripts" ]; then

    hostname='localhost'
    read -ep "hostname/ip [$hostname]: " input
    hostname=${input:-$hostname}
    JmxUpdate hostname_val $hostname

    port=9443
    read -ep "port [$port]: " input
    port=${input:-$port}
    JmxUpdate port_val $port

    adminuser='admin'
    read -ep "admin username [$adminuser]: " input
    adminuser=${input:-$adminuser}
    JmxUpdate admin_user_val $adminuser

    adminpass='admin'
    read -ep "admin password [$adminpass]: " input
    adminpass=${input:-$adminpass}
    cred=$(echo -n $adminuser:$adminpass | base64)
    JmxUpdate admin_password_val $adminpass
    JmxUpdate base64AdminCred_val $cred

    NoUser=500
    read -ep "number of users [$NoUser]: " input
    NoUser=${input:-$NoUser}
    JmxUpdate userCount_val $NoUser

    NoApps=200
    read -ep "number of apps [$NoApps]: " input
    NoApps=${input:-$NoApps}
    JmxUpdate sp_apps_val $NoApps

    startCounter=1
    read -ep "start counter [$startCounter]: " input
    startCounter=${input:-$startCounter}
    JmxUpdate startCounter_val $startCounter

    concurrency=50
    read -ep "threads [$concurrency]: " input
    concurrency=${input:-$concurrency}
    JmxUpdate concurrency_val $concurrency

    timeToRunInMinutes=30
    read -ep "time to run in minutes [$timeToRunInMinutes]: " input
    timeToRunInMinutes=${input:-$timeToRunInMinutes}
    timeToRun=$(($timeToRunInMinutes * 60))
    JmxUpdate timeToRun_val $timeToRun

    rampUpPeriod=10
    read -ep "ramp up time [$rampUpPeriod]: " input
    rampUpPeriod=${input:-$rampUpPeriod}
    JmxUpdate rampUpPeriod_val $rampUpPeriod

    echo "Common JMX scripts has generated in jmx_scripts !"
else
    echo "Unable to get the base jmx scripts !"
fi
