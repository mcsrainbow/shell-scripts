#!/bin/bash 

# default settings
retry=2 # retry times
timeout=3 # timeout seconds
output=/tmp/ping.output # output file
subnet=$1 # C type subnet

# function print_help
function print_help(){
  echo "Examples:"
  echo ${0} 172.17.32
  echo ${0} 192.168.1 unable
  exit 1
}

# check the parameter
if [ $# -lt 1 ]; then
  print_help
fi

# check the network parameter's format
count=0
for i in $(echo $1 |sed 's/\./ /g')
do
  count=$((${count}+1))
done
if [ ${count} -ne 3 ]; then
  print_help
fi

# clean the output file
> ${output}

function runping(){
if $(echo $OSTYPE |grep -q darwin); then
  # Mac OS
  ping -t ${retry} -W ${timeout}000 -q ${subnet}.${i}
else
  # Linux/BSD
  ping -c ${retry} -w ${timeout} -q ${subnet}.${i}
fi
}

function pingable(){
  runping &> /dev/null && echo ${i} >> ${output}
}

function unpingable(){
  runping &> /dev/null || echo ${i} >> ${output} 
}

# get the check type
if [ "$2" == "unable" ]; then
  status="unpingable"
else
  status="pingable"
fi

# ping as paraller mode and write output into file
for i in {1..255}
do 
  ${status} &
done

# wait for all ping processes done
wait

# print output with better order
sum=$(wc -l ${output} |awk '{print $1}')
echo "There are '${sum}' '${status}' ips begin with '${subnet}.' :"
cat ${output} |sort |xargs -n 20 echo " "
