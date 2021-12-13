# Network Latency Report

The shell script is used the undeline technology provided by mtr tool available in https://www.bitwizard.nl/mtr/. Since the mtr --report command only output once its hard to identify the network issues that could occur time to time. The sript is capable of executing the the MTR --report in a loop and log the same in to a log file specifed by the date.

#### usage

```sh
$ cd mtr-network-latency-report
$ sh mtr-report-generator.sh <number of itterations the loop should continue>
$ sh mtr-report-generator.sh 5
```
** any negative number pass as the itteration will will run the loop infinettly.
