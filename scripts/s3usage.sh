#!/bin/bash

bucket_list=$(s3cmd ls|awk '{print $NF}' |xargs)

for bucket in $bucket_list
do
  bucket_name=$(echo $bucket |cut -d/ -f3)
  command="aws s3api list-objects --bucket $bucket_name --output json --query \"[sum(Contents[].Size)]\" | grep [0-9] | awk '{print \$1}'"
  bucket_size=$(eval $command)
  bucket_size_mb=$(($bucket_size/1024/1024))
  if [[ $bucket_size_mb -gt 1024 ]]; then
    bucket_size_gb=$(($bucket_size_mb/1024))
    echo "${bucket_name} ${bucket_size_gb}GB"
  else
    echo "${bucket_name} ${bucket_size_mb}MB"
  fi
done
