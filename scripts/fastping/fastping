#!/bin/bash 

# default settings
subnet=$1 # C type subnet
retry=1 # retry times
timeout=1 # timeout seconds
output=/tmp/ping.output # output file

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

function pingable(){
  ping -c ${retry} -w ${timeout} -q ${subnet}.${i} &> /dev/null && echo ${i} >> ${output}
}

function unpingable(){
  ping -c ${retry} -w ${timeout} -q ${subnet}.${i} &> /dev/null || echo ${i} >> ${output}
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
echo "There are \"${sum}\" \"${status}\" ips begin with \"${subnet}.\" :"
cat ${output} | sort -t"." -k1,1n -k2,2n -k3,3n -k4,4n | xargs -n 20 echo " "
