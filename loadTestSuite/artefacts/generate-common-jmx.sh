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
    read -ep "hostname/ip [$hostname]: " input
    hostname=${input:-$hostname}

    port=9443
    read -ep "port [$port]: " input
    port=${input:-$port}

    adminuser='admin'
    read -ep "admin username [$adminuser]: " input
    adminuser=${input:-$adminuser}

    adminpass='admin'
    read -ep "admin password [$adminpass]: " input
    adminpass=${input:-$adminpass}

    NoUser=500
    read -ep "number of users [$NoUser]: " input
    NoUser=${input:-$NoUser}

    NoApps=200
    read -ep "number of apps [$NoApps]: " input
    NoApps=${input:-$NoApps}

    startCounter=1
    read -ep "start counter [$startCounter]: " input
    startCounter=${input:-$startCounter}

    concurrency=50
    read -ep "threads [$concurrency]: " input
    concurrency=${input:-$concurrency}

    timeToRunInMinutes=30
    read -ep "time to run in minutes [$timeToRunInMinutes]: " input
    timeToRunInMinutes=${input:-$timeToRunInMinutes}

    rampUpPeriod=10
    read -ep "ramp up time [$rampUpPeriod]: " input
    rampUpPeriod=${input:-$rampUpPeriod}

    timeToRun=$(($timeToRunInMinutes * 60))

    cred=$(echo -n $adminuser:$adminpass | base64)

    sed -i.bkp -e 's/hostname_val/'$hostname'/g' $CURRENTDIR/jmx_scripts/*

    sed -i.bkp 's/port_val/'$port'/g' $CURRENTDIR/jmx_scripts/*
  
    sed -i.bkp 's/userCount_val/'$NoUser'/g' $CURRENTDIR/jmx_scripts/*

    sed -i.bkp 's/sp_apps_val/'$NoApps'/g' $CURRENTDIR/jmx_scripts/*

    sed -i.bkp 's/startCounter_val/'$startCounter'/g' $CURRENTDIR/jmx_scripts/*

    ###
    sed -i.bkp 's/timeToRun_val/'$timeToRun'/g' $CURRENTDIR/jmx_scripts/*

    sed -i.bkp 's/concurrency_val/'$concurrency'/g' $CURRENTDIR/jmx_scripts/*

    sed -i.bkp 's/rampUpPeriod_val/'$rampUpPeriod'/g' $CURRENTDIR/jmx_scripts/*

    ##
    sed -i.bkp 's/base64AdminCred_val/'$cred'/g' $CURRENTDIR/jmx_scripts/*

    sed -i.bkp 's/admin_user_val/'$adminuser'/g' $CURRENTDIR/jmx_scripts/*

    sed -i.bkp 's/admin_password_val/'$adminpass'/g' $CURRENTDIR/jmx_scripts/*

    rm -rf $CURRENTDIR/jmx_scripts/*.bkp
    echo "Common JMX scripts has generated in jmx_scripts !"
else
    echo "Unable to get the base jmx scripts !"
fi
