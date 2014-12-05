#!/bin/bash

DATE=$(date +%Y-%m-%d)
HOST=sftp.heylinux.com
USER=username
PASS=password
PORT=22
LOCAL_PATH=/root/sftp_hdfs/data
REMOTE_PATH=/downloads
HDFS_PATH=/data/downloads
FILTER_STRING=HeyLinux

echo "###########${DATE}###########"

list=$(lftp -u ${USER},${PASS} -p ${PORT} sftp://${HOST} <<EOF
ls ${REMOTE_PATH}
EOF
)

mget(){
lftp -u ${USER},${PASS} -p ${PORT} sftp://${HOST} <<EOF
lcd ${LOCAL_PATH}/$1
get ${REMOTE_PATH}/$2
EOF
}

for item in $list
do 
  if $(echo ${item} | grep -q $FILTER_STRING); then
    DATE_1=$(echo ${item} | awk -F "_" '{print $(NF-1)}')
    if [ ! -z "${DATE_1}" ]; then
      DATE_2=$(date +%Y-%m-%d -d ${DATE_1})
      mkdir -p ${LOCAL_PATH}/${DATE_2}
      if [ ! -f ${LOCAL_PATH}/${DATE_2}/${item}_SUCCESS ]; then
        rm -f ${LOCAL_PATH}/${DATE_2}/${item}
        echo "Downloading ${REMOTE_PATH}/${item} to ${LOCAL_PATH}/${DATE_2}"
        mget ${DATE_2} ${item}
        if [ $? -eq 0 ]; then
          touch ${LOCAL_PATH}/${DATE_2}/${item}_SUCCESS
        fi
      fi
    fi
  fi
done

for DATE_2 in $(ls -1 ${LOCAL_PATH}/ | xargs -n 1 basename)
do
  hadoop fs -test -e ${HDFS_PATH}/${DATE_2} || hadoop fs -mkdir ${HDFS_PATH}/${DATE_2}
  if ! $(hadoop fs -test -e ${HDFS_PATH}/${DATE_2}/_SUCCESS); then
    for file in $(ls -1 ${LOCAL_PATH}/${DATE_2}/*_SUCCESS | xargs -n 1 basename | awk -F "_SUCCESS" '{print $1}')
    do
      if ! $(hadoop fs -test -e ${HDFS_PATH}/${DATE_2}/${file}_SUCCESS); then
        echo "Uploading ${LOCAL_PATH}/${DATE_2}/${file} to ${HDFS_PATH}/${DATE_2}"
        hadoop fs -test -e ${HDFS_PATH}/${DATE_2}/${file} && hadoop fs -rm ${HDFS_PATH}/${DATE_2}/${file}
        hadoop fs -put ${LOCAL_PATH}/${DATE_2}/${file} ${HDFS_PATH}/${DATE_2}
        if [ $? -eq 0 ]; then
          hadoop fs -touchz ${HDFS_PATH}/${DATE_2}/${file}_SUCCESS
        fi
      fi
    done
    LOCAL_COUNT=$(ls -1 ${LOCAL_PATH}/${DATE_2}/*_SUCCESS |wc -l)
    LOCAL_COUNT_REAL=$(ls -1 ${LOCAL_PATH}/${DATE_2}/ | grep -v _SUCCESS |wc -l)
    HDFS_COUNT=$(hadoop fs -ls ${HDFS_PATH}/${DATE_2}/*_SUCCESS |grep SUCCESS |wc -l)
    if [ ${LOCAL_COUNT} -gt 0 ] && [ ${LOCAL_COUNT} -eq ${LOCAL_COUNT_REAL} ] && [ ${LOCAL_COUNT} -eq ${HDFS_COUNT} ]; then
      hadoop fs -rm ${HDFS_PATH}/${DATE_2}/*[a-z]_SUCCESS
      hadoop fs -touchz ${HDFS_PATH}/${DATE_2}/_SUCCESS
    fi
  fi
done
