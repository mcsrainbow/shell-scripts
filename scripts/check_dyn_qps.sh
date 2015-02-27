#!/bin/bash
#
# Get QPS report from Dyn via REST API
#
# Author: Dong Guo
# Last Modified: 2013/09/18 by Dong Guo

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

# Threshold Numbers
warn=$2
crit=$3

customer_name="YOUR-CUSTOMER-NAME"
user_name="YOUR-USER-NAME"
password="YOUR-PASSWORD"

domain="YOUR.DOMAIN.COM"
format="Content-Type: application/yaml"
api_url="https://api.dynect.net"
session_api="https://api.dynect.net/REST/Session/"
report_api="https://api.dynect.net/REST/QPSReport/"

end_ts=$(date +%s)

if [ $# != 3 ]; then
  echo $"Usage: $0 {daily|weekly|monthly} {warn} {crit}"
  exit 0
fi

case "$1" in
  daily)
    start_ts=$(($end_ts-86400))
    ;;
  weekly)
    start_ts=$(($end_ts-7*86400))
    ;;
  monthly)
    start_ts=$(($end_ts-30*86400))
    ;;
  *)
    echo $"Usage: $0 {daily|weekly|monthly} {warn} {crit}"
    exit 0
    ;;
esac

tmpfile=/tmp/qps_report_from_dyn_tmp.txt
> $tmpfile
    
token=$(curl -s -H "$format" -X POST $session_api -d "{customer_name: $customer_name,user_name: $user_name,password: $password}" | grep token | awk -F ",|:" '{print $3}')
curl -s -H "$format" -H "Auth-Token: $token" -X POST $report_api -d "{start_ts: $start_ts,end_ts: $end_ts,breakdown: zones}" > $tmpfile.raw

grep -q '/REST/Job/' $tmpfile.raw
if [ $? -eq 0 ]; then
  get_url=$(cat $tmpfile.raw)
  sleep 2
  curl -s -H "$format" -H "Auth-Token: $token" -X GET $api_url$get_url > $tmpfile.raw
fi

for item in $(grep $domain $tmpfile.raw) 
do
  value=$(echo $item | cut -d "," -f 3 | cut -d "'" -f 1)
  qps=$(($value/300))
  echo $qps >> $tmpfile
done

countall=$(wc -l $tmpfile | awk '{print $1}')
tailnum=$(($countall*95/100))
sort -rn $tmpfile | tail -n $tailnum  | grep -vw 0 > ${tmpfile}.tailnum

count=$(wc -l ${tmpfile}.tailnum | awk '{print $1}')
sum=$(awk '{i+=$1}END{print i}' ${tmpfile}.tailnum)
max_qps=$(head -n 1 ${tmpfile}.tailnum)
min_qps=$(tail -n 1 ${tmpfile}.tailnum)
avg_qps=$(($sum/$count))
perfdata="max_qps=$max_qps;$warn;$crit min_qps=$min_qps avg_qps=$avg_qps"

if [ "$max_qps" -gt "$crit" ]; then
  echo -n "CRIT. max_qps $max_qps is greater than $crit | $perfdata"
  exit $STATE_CRITICAL
elif [ "$max_qps" -gt "$warn" ]; then
  echo -n "WARN. max_qps $max_qps is greater than $warn | $perfdata"
  exit $STATE_WARNING
else
  echo -n "OK. max_qps is $max_qps | $perfdata"
  exit $STATE_OK
fi
