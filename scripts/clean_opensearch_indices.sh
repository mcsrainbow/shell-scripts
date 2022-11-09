#!/bin/bash

opensearch_url="https://opensearch.heylinux.com"
user_pass="username:password"

indices_items=$(curl -s -XGET -k -u ${user_pass} "${opensearch_url}/_cat/indices?pretty=true" | awk '{print $3}' | grep -E '^[a-z]|^[A-Z]' | xargs)
clean_date=$(date --date="30 days ago" +%Y%m%d)

for index_item in ${indices_items}; do
  index_item_date=$(echo ${index_item} | awk -F '-' '{print $NF}' | sed s/[.]//g | grep -Ev '[a-z]|[A-Z]') 
  if [ ! -z "${index_item_date}" ] && [ ${index_item_date} -lt ${clean_date} ]; then
    echo "Deleting index: ${index_item}"
    curl -s -XDELETE -k -u ${user_pass} "${opensearch_url}/${index_item}"
  fi
done
