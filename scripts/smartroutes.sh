#!/bin/bash 
# Mac OS X Only

basedir=$(dirname $0)
apnic_data_url="http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest"
apnic_data="${basedir}/apnic.data"
subnet_exceptions=(
172.21.1.0/24
66.102.255.51/32
) # subnets not in apnic_data CN section, just some examples, change/remove them

function check_root(){
  if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
  fi
}

function print_help(){
  echo "Usage:"
  echo "  ${0} {on|off}"
  echo "  ${0} [force|exception] {on|off}"
}

function check_data(){
  if [[ ! -f ${apnic_data} ]]; then
    update_data
  fi

  rawnet_sign=$(grep CN ${apnic_data} |grep ipv4 |head -n 1 |awk -F '|' '{print $4"/"$5}')
  rawnet_sign_formatted=$(format_subnet ${rawnet_sign})
  subnet_sign=$(format_subnet_netstat ${rawnet_sign_formatted})
}

function check_size(){
  apnic_data_size=$(curl --head -s ${apnic_data_url} |grep Content-Length |awk '{print $2}' |col -b)
  apnic_data_size_local=$(ls -l ${apnic_data} |awk '{print $5}')

  if [[ "${apnic_data_size}" != "${apnic_data_size_local}" ]]; then
    update_data
  fi
}

function update_data(){
  echo "Downloading the latest APNIC data as ${apnic_data}..."

  curl --progress-bar -o ${apnic_data} ${apnic_data_url}
  if [[ $? -ne 0 ]]; then
    exit 1
  fi
}

function format_subnet(){
  subnet=${1}
  subneti=$(echo ${subnet} |cut -d/ -f1)
  rawnetm=$(echo ${subnet} |cut -d/ -f2)
  subnetm=$(awk -v c=${rawnetm} 'function log2(x){if(x<2)return(pow);pow--;return(log2(x/2))}BEGIN{pow=32;print log2(c)}')

  echo ${subneti}/${subnetm}
}

function check_status(){
  netstat -rn |grep -Eq "^${subnet_sign}"
  if [[ $? -ne 0 ]]; then
    echo "SmartRoutes is OFF"
  else
    echo "SmartRoutes is ON"
  fi

  if [[ ! -z "${subnet_exceptions[0]}" ]]; then
    subnet_exception_formatted=$(format_subnet_netstat ${subnet_exceptions[0]})

    netstat -rn |grep -Eq "^${subnet_exception_formatted}"
    if [[ $? -ne 0 ]]; then
      echo "SmartRoutes Exception is OFF"
    else
      echo "SmartRoutes Exception is ON"
    fi
  fi
}

function add_routes(){
  oldgw=$(netstat -nr |grep '^default' |grep -v 'ppp' |sed 's/default *\([0-9\.]*\) .*/\1/' |grep -Ev '^$')
  dscacheutil -flushcache

  all_subs=$(grep CN ${apnic_data} |grep ipv4 |awk -F '|' '{print $4"/"$5}')
  echo -n "Adding the routes..."
  for subnet in ${all_subs}; do
    subnet_formatted=$(format_subnet ${subnet})
    route add ${subnet_formatted} "${oldgw}" > /dev/null
  done
  echo " Done"
}

function del_routes(){
  all_subs=$(grep CN ${apnic_data} |grep ipv4 |awk -F '|' '{print $4"/"$5}')
  echo -n "Deleting the routes..."
  for subnet in ${all_subs}; do
    subnet_formatted=$(format_subnet ${subnet})
    route delete ${subnet_formatted} > /dev/null
  done
  echo " Done"
}

function run_smartroutes(){
  netstat -rn |grep -Eq "^${subnet_sign}"
  if [[ $? -ne 0 ]]; then
    add_routes
  else
    echo "SmartRoutes is already ON"
  fi
}

function del_smartroutes(){
  netstat -rn |grep -Eq "^${subnet_sign}"
  if [[ $? -eq 0 ]]; then
    del_routes
  else
    echo "SmartRoutes is already OFF"
  fi
}

function format_subnet_netstat(){
  subnet_exception=${1}
  a=$(echo ${subnet_exception} |cut -d/ -f1 |cut -d. -f1)
  b=$(echo ${subnet_exception} |cut -d/ -f1 |cut -d. -f2)
  c=$(echo ${subnet_exception} |cut -d/ -f1 |cut -d. -f3)
  d=$(echo ${subnet_exception} |cut -d/ -f1 |cut -d. -f4)
  m=$(echo ${subnet_exception} |cut -d/ -f2)

  if [[ $m -gt 24 ]]; then
    echo "$a.$b.$c.$d/$m"
  elif [[ $m -le 24 ]] && [[ $m -gt 16 ]]; then
    echo "$a.$b.$c/$m"
  elif [[ $m -le 16 ]] && [[ $m -gt 8 ]]; then
    echo "$a.$b/$m"
  elif [[ $m -eq 8 ]]; then
    echo "$a/$m"
  fi
}

function add_exception(){
  if [[ ! -z "${subnet_exceptions[0]}" ]]; then
    subnet_exception_formatted=$(format_subnet_netstat ${subnet_exceptions[0]})

    netstat -rn |grep -Eq "^${subnet_exception_formatted}"
    if [[ $? -ne 0 ]]; then
      oldgw=$(netstat -nr |grep '^default' |grep -v 'ppp' |sed 's/default *\([0-9\.]*\) .*/\1/' |grep -Ev '^$')
      dscacheutil -flushcache

      echo -n "Adding the routes..."
      for subnet_exception in ${subnet_exceptions[@]}; do
        route add ${subnet_exception} "${oldgw}" > /dev/null
      done
      echo " Done"
    else
      echo "SmartRoutes Exception is already ON"
    fi
  fi
}

function del_exception(){
  if [[ ! -z "${subnet_exceptions[0]}" ]]; then
    subnet_exception_formatted=$(format_subnet_netstat ${subnet_exceptions[0]})

    netstat -rn |grep -Eq "^${subnet_exception_formatted}"
    if [[ $? -ne 0 ]]; then
      echo "SmartRoutes Exception is already OFF"
    else
      echo -n "Deleting the routes..."
      for subnet_exception in ${subnet_exceptions[@]}; do
        route delete ${subnet_exception} > /dev/null
      done
      echo " Done"
    fi
  fi
}

check_root
check_data
case $1 in
  on)
    check_size
    run_smartroutes
    ;;
  off)
    del_smartroutes
    ;;
  force)
    case $2 in
      on)
        add_routes
        ;;
      off)
        del_routes
        ;;
      *)
        check_status
        print_help
        ;;
    esac
    ;;
  exception)
    case $2 in
      on)
        add_exception
        ;;
      off)
        del_exception
        ;;
      *)
        check_status
        print_help
        ;;
    esac
    ;;
  *)
    check_status
    print_help
    ;;
esac
