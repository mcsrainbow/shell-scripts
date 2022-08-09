#!/bin/bash
# Description: Create IAM User, Group, Policy and genreate AKSK
# Author: Damon Guo
# Content:
# .
# ├── create_iam_user_aksk.sh
# ├── generated_aksk
# │   ├── HeyApp.json
# └── policy_data
#     └── HeyAppServicePolicy.json

user_group_policy=(
HeyApp,HeyAppGroup,HeyAppServicePolicy
)

aws_account_id=857857857857
aws_cmd="/usr/local/bin/aws"
srv_path="heysrv"
all_users="$(${aws_cmd} iam list-users --path /${srv_path}/ | grep -w UserName | xargs)"
all_groups="$(${aws_cmd} iam list-groups --path /${srv_path}/ | grep -w GroupName | xargs)"
all_policies="$(${aws_cmd} iam list-policies --path /${srv_path}/ | grep -w PolicyName | xargs)"

for item in ${user_group_policy[@]}; do
  user_name=$(echo ${item} | cut -d, -f1)
  group_name=$(echo ${item} | cut -d, -f2)
  policy_name=$(echo ${item} | cut -d, -f3)

  echo ""
  echo "INFO: Checking User_Group_Policy: ${item}..."

  if $(echo ${all_groups} | grep -wq ${group_name}); then
    echo "INFO: Found Group: /${srv_path}/${group_name}"
  else
    ${aws_cmd} iam create-group --path /${srv_path}/ --group-name ${group_name}
  fi

  if $(echo ${all_policies} | grep -wq ${policy_name}); then
    echo "INFO: Found Policy: /${srv_path}/${policy_name}"
  else
    ${aws_cmd} iam create-policy --path /${srv_path}/ --policy-name ${policy_name} --policy-document file://policy_data/${policy_name}.json
  fi

  group_policies=$(${aws_cmd} iam list-attached-group-policies --group-name ${group_name} | grep -w PolicyName | xargs)
  if $(echo ${group_policies} | grep -wq ${policy_name}); then
    echo "INFO: Found Policy: /${srv_path}/${policy_name} in Group: /${srv_path}/${group_name}"
  else
    ${aws_cmd} iam attach-group-policy --policy-arn arn:aws:iam::${aws_account_id}:policy/${srv_path}/${policy_name} --group-name ${group_name}
  fi

  if $(echo ${all_users} | grep -wq ${user_name}); then
    echo "INFO: Found User: /${srv_path}/${user_name}"
  else
    ${aws_cmd} iam create-user --path /${srv_path}/ --user-name ${user_name}
  fi

  user_groups=$(${aws_cmd} iam list-groups-for-user --user-name ${user_name} | grep -w GroupName | xargs)
  if $(echo ${user_groups} | grep -wq ${group_name}); then
    echo "INFO: Found Group: /${srv_path}/${group_name} of User: /${srv_path}/${user_name}"
  else
    ${aws_cmd} iam add-user-to-group --group-name ${group_name} --user-name ${user_name}
  fi

  user_all_access_keys=$(${aws_cmd} iam list-access-keys --user-name ${user_name} | grep -w AccessKeyId | cut -d: -f2 | cut -d\" -f2 | xargs)
  if [ -a generated_aksk/${user_name}.json ]; then
    access_key=$(grep -w AccessKeyId generated_aksk/${user_name}.json | cut -d: -f2 | cut -d\" -f2)
  fi
  if [ ! -z "${access_key}" ]; then
    if $(echo ${user_all_access_keys} | grep -q ${access_key}); then
      echo "INFO: Found Access Key: ${access_key} in generated_aksk/${user_name}.json"
      continue
    fi
  fi
  echo "INFO: Generated AKSK of User: /${srv_path}/${user_name} in generated_aksk/${user_name}.json"
  ${aws_cmd} iam create-access-key --user-name ${user_name} > generated_aksk/${user_name}.json
done
