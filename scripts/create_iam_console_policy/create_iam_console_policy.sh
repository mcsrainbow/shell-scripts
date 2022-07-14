#!/bin/bash

declare -A group_policy_dict=(
["HEY_AWS_DataSteward"]="AWSGlueConsoleFullAccess AwsGlueDataBrewFullAccessPolicy CloudWatchFullAccess"
)

secure_policies="HEY_AWS_MFAPolicy HEY_AWS_SourcePolicy"

aws_account_id=857857857857
aws_cmd="/usr/local/bin/aws"
srv_path=heysrv
srv_policies="$(${aws_cmd} iam list-policies --path /${srv_path}/ | grep -w PolicyName | xargs)"

for secure_policy_name in ${secure_policies}; do
  if $(echo ${srv_policies} | grep -wq ${secure_policy_name}); then
    echo "Found Policy: /${srv_path}/${secure_policy_name}"
  else
    ${aws_cmd} iam create-policy --path /${srv_path}/ --policy-name ${secure_policy_name} --policy-document file://policy_data/${secure_policy_name}.json
  fi
done

for key in "${!group_policy_dict[@]}"; do
  group_name=${key}
  group_policies="${group_policy_dict["${key}"]}"

  echo ""
  echo "INFO: Checking group: ${key}..."

  if $(${aws_cmd} iam get-group --group-name ${group_name} 1>/dev/null 2>/dev/null); then
    echo "Found Group: ${group_name}"
  else
    echo "ERROR: No such group: ${group_name}"
    exit 1
  fi

  attached_group_policies=$(${aws_cmd} iam list-attached-group-policies --group-name ${group_name} | grep -w PolicyName | xargs)

  for secure_policy_name in ${secure_policies}; do
  if $(echo ${attached_group_policies} | grep -wq ${secure_policy_name}); then
      echo "Found Policy: /${srv_path}/${secure_policy_name} in Group: ${group_name}"
    else
      echo "Attaching Policy: /${srv_path}/${secure_policy_name} to Group: ${group_name}..."
      ${aws_cmd} iam attach-group-policy --policy-arn arn:aws:iam::${aws_account_id}:policy/${srv_path}/${secure_policy_name} --group-name ${group_name}
    fi
  done

  for policy_name in ${group_policies}; do
    if $(echo ${attached_group_policies} | grep -wq ${policy_name}); then
      echo "Found Policy: ${policy_name} in Group: ${group_name}"
    else
      echo "Attaching Policy: ${policy_name} to Group: ${group_name}..."
      ${aws_cmd} iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/${policy_name} --group-name ${group_name}
    fi
  done
done
