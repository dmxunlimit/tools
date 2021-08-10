#!/bin/bash

sleep 1

while true; do

    if [ $(find $2 -name "*.jmx" | wc -l) -gt 0 ]; then
        echo "New JMX scripts are available to Process !"
    else
        echo "No JMX scripts are available to Process !, Hence Shutting down ..."
        break
    fi

    for f in $(find $2 -name *.jmx | sort -n); do

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

        sh $WRKDIR/.artefacts/jmeter/bin/jmeter -n -t $FILE -l $RESULTDIR/$RESULTFILE -e -o $RESULTDIR

        cp $FILE $RESULTDIR
        rm -rf $FILE

        echo "Sleeping for 5 seconds ..."
        sleep 5

    done

done

