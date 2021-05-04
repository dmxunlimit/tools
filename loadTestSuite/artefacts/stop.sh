#!/bin/sh

checkProsess() {
    lprocess=$(ps aux | grep -v grep | grep loadtest.sh)
    jprocess=$(ps aux | grep -v grep | grep jmeter)

    if [ ! -z "$lprocess" ]; then
        echo "\nLoadTest Process :"
        echo $lprocess
        lprocess=$(echo $lprocess | awk '{print $2}')
    fi
    if [ ! -z "$jprocess" ]; then
        echo "\nJmeter Process :"
        echo $jprocess
        jprocess=$(echo $jprocess | awk '{print $2}')
    fi

}

checkProsess

if [ ! -z "$lprocess" ] || [ ! -z "$jprocess" ]; then
    echo ""
    read -p "Do you wish to kill the service y/n :" killme
    if [ "$killme" = "y" ]; then

        while true; do

            if [ ! -z "$lprocess" ]; then
                for i in $lprocess; do
                    sudo kill -9 $i
                done
            fi

            if [ ! -z "$jprocess" ]; then
                for i in $jprocess; do
                    sudo kill -9 $i
                done
            fi

            if [ -z "$lprocess" ] && [ -z "$jprocess" ]; then
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
