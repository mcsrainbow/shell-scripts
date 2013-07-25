#!/bin/bash
# 
# Generic HDFS clean up script
# Author: Dong Guo
# Last modified: 2013/07/25
# Email: dong.guo@symbio.com
#
# Use "./hdfs_clean.sh delete" to trigger the action

#given above list, create a script to find directories older than X days
DATA_FILE="data.txt"

#2. script should take a configuration file, with delete days threshold and list of directories
DELETE_DAYS_THRESHOLD=9
DIRECTORIES_LIST=(
/user/oozie/data/dpp/hive
/user/oozie/data/dpp/log
/user/oozie/data/dpp/ad_groups_property_stats
/user/oozie/data/dpp/circuitbreaker2
)

NOW_TIMESTAMP=`date +%s`
THRESHOLD_TIMESTAMP=$(($NOW_TIMESTAMP-$DELETE_DAYS_THRESHOLD*86400))

#4. directory depth under /user/oozie/data/dpp/hive/ can be variable
DIRECTORY_DEPTH=2
function check_dir_withdepth(){
  DEPTH=$(($DIRECTORY_DEPTH+6))
  SUBDIRECTORIES=`grep -w $DIRECTORY $DATA_FILE | grep "drwxr" | awk '{print $8}' | cut -d / -f 1-$DEPTH | grep [2][0-9][0-9][0-9]-[0-9][0-9]`
}

function check_dir_formated(){
  echo "Here are the directories older than $DELETE_DAYS_THRESHOLD days:"
  for DIRECTORY in ${DIRECTORIES_LIST[@]}
  do 
    if [ $DIRECTORY == "/user/oozie/data/dpp/hive" ]; then
      check_dir_withdepth  
    else      
      #3. ignore files, look at directories only
      SUBDIRECTORIES=`grep -w $DIRECTORY $DATA_FILE | grep "drwxr" | awk '{print $8}' | grep [2][0-9][0-9][0-9]-[0-9][0-9]`
    fi
    if [ ! -z "$SUBDIRECTORIES" ]; then
      for SUBDIRECTORY in ${SUBDIRECTORIES[@]}
      do 
        #5. use directory name instead of last modified time
        DIRECTORIES_TIME=`echo $SUBDIRECTORY | awk -F "/" '{print $NF}' | awk -F "=" '{print $NF}' | awk -F "-" '{print $1"-"$2"-"$3}'`
        DIRECTORIES_TIMESTAMP=`date -d $DIRECTORIES_TIME +%s`
        if [ $DIRECTORIES_TIMESTAMP -lt $THRESHOLD_TIMESTAMP ]; then
          #1. script should run in DEBUG mode by default (print only) and has a switch to actually run delete
          if [ ! -z $1 ] && [ $1 = "delete" ]; then
            echo "sudo -u oozie hadoop fs -rmr $SUBDIRECTORY"
          else
            echo "$DIRECTORIES_TIME $SUBDIRECTORY"
          fi
        fi
      done
    fi
  done
}

#6. directory date can be in the format of dt=2013-06-30-00-00 or dt=2013-04-19 or 2013-05-14-18-00; print directories not matching these pattern
function check_dir_noformat(){
  echo ""
  echo "Here are the directories without data format:"
  for DIRECTORY in ${DIRECTORIES_LIST[@]}
  do 
    NODATA_DIRECTORIES=`grep -w $DIRECTORY $DATA_FILE | grep "drwxr" | awk '{print $8}' | grep -v [2][0-9][0-9][0-9]-[0-9][0-9]*`
    if [ ! -z "$NODATA_DIRECTORIES" ]; then
      echo "$NODATA_DIRECTORIES"
    fi
  done
}

check_dir_formated
check_dir_noformat
