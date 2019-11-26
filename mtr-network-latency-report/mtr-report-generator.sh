count=0
itterations=$1

while [ true ]
do
mtr --report --report-cycles 10 $2 > mtr_latency_report_"$(date +%F_%R)".log
   if [ $itterations -gt 0 ]
   then
   count=`expr $count + 1`
        if [ $itterations -eq $count ]
        then
        break;
        fi
   fi
done