#!/bin/sh
# Adjust variables to fit your environment as necessary.

commandfile='/var/spool/icinga/cmd/icinga.cmd'

if [ "$#" -ne 1 ]; then
  echo "$0 hostname"
  exit
fi

declare -i start=$(date +%s)
declare -i end=$start+900
/usr/bin/printf "[%lu] SCHEDULE_HOST_DOWNTIME;$1;$start;$end;1;0;1;AS_spindown;AS spinning down\n" $start > $commandfile
