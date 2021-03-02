#!/bin/sh

checkProsess() {
    lprocess=$(ps aux | grep -v grep | grep loadtest | awk '{print $2}')
    jprocess=$(ps aux | grep -v grep | grep jmeter | awk '{print $2}')

    if [ ! -z "$lprocess" ]; then
        echo "LoadTest PID :$lprocess"
    fi
    if [ ! -z "$jprocess" ]; then
        echo "Jmeter PID :$jprocess"
    fi

}

checkProsess

if [ ! -z "$lprocess" ] || [ ! -z "$jprocess" ]; then
    read -p "Do you wish to kill the service y/n :" killme
    if [ "$killme" = "y" ]; then

        while true; do

            if [ ! -z $lprocess ]; then
                sudo kill -9 $lprocess
            elif [ ! -z "$jprocess" ]; then
                for i in $jprocess; do
                    sudo kill -9 $i
                done
            else
                echo "Successfully stoped the LoadTest !"
                break
            fi
            sleep 1
            checkProsess
        done
    fi

else
    echo "No running process found for LoadTest !"
fi
