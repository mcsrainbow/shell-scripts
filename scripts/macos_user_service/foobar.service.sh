#!/bin/bash
#
# This script is used to start the FooBar service
#
# Location: /Users/username/services/bin/foobar.service.sh
# Depends_on: launchctl load /Users/username/Library/LaunchAgents/com.user.foobar.service.plist
#

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Service
service_base=/Users/username/services
service_name=foobar.service

export FOOBAR_START=yes

service_cmd="/opt/homebrew/bin/foobar tom \
--target=jerry \
--catch"

cmd_basestr=$(echo ${service_cmd} | cut -d" " -f1-2)
cmd_found=$(ps aux | grep "${cmd_basestr}" | grep -v grep)

if [[ ! -z "${cmd_found}" ]]; then
  echo -e "ERROR: Found the Running Command:\n       ${cmd_found}"
  exit 1
fi

${service_cmd} >> ${service_base}/logs/${service_name}.log 2>&1
