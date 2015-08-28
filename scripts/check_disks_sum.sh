#!/bin/bash 
# This script checks all alerts for check_mk-df on Check_MK
# Then summarise the output

function get_info(){
  retval=$1
  echo "GET services
Columns: host_display_name state description
Separators: 10 32 44 124
Filter: check_command = check_mk-df
Filter: active_checks_enabled = 0
Filter: scheduled_downtime_depth = 0
Filter: host_scheduled_downtime_depth = 0
Filter: acknowledged = 0
Filter: state = ${retval}" |unixcat /var/spool/icinga/cmd/live\
|awk '{print $1}' |sort |uniq -c\
|awk '{print " "$1 " disk(s) on " $2}'|tr '\n' ';'
}

warn_msg="$(get_info 1)"
crit_msg="$(get_info 2)"
unkn_msg="$(get_info 3)"

[[ "$warn_msg" ]] && { retval=1; echo -n "WARN.$warn_msg  "; }
[[ "$crit_msg" ]] && { retval=2; echo -n "CRIT.$crit_msg  "; }
[[ "$unkn_msg" ]] && { retval=2; echo -n "UNKN.$unkn_msg  "; }
[[ ${retval} > 0 ]] && exit ${retval}

echo "OK. No failed disk found"; exit 0
