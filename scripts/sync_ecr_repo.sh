#!/bin/bash

aws_cli="/usr/bin/aws"
aws_region="us-west-1"

image_prefix="dkr.ecr.${aws_region}.amazonaws.com"
image_list=(
redis:latest
openjdk:8-jdk
)

policy_json='{"Version":"2008-10-17",
"Statement":
[{"Sid":"AllowCrossAccountPull",
"Effect":"Allow",
"Principal":
{"AWS":"arn:aws:iam::857857857857:root"},
"Action":
["ecr:BatchCheckLayerAvailability",
"ecr:BatchGetImage",
"ecr:GetDownloadUrlForLayer"]}]}'

function check_params(){
  if [ $# -ne 2 ]; then
    echo "Usage: ${0} src_aws_id dst_aws_id"
    echo "       ${0} 233233233233 857857857857"
    exit 1
  else
    src_aws_id=${1}
    dst_aws_id=${2}
    
    docker_password=$(${aws_cli} ecr get-login-password --region ${aws_region})
  fi
}

function pull_ecr_images(){
  docker login --username AWS --password $docker_password ${src_aws_id}.${image_prefix}
  for image in ${image_list[@]}; do
    docker pull ${src_aws_id}.${image_prefix}/${image}
  done
}

function push_ecr_images(){
  docker login --username AWS --password $docker_password ${dst_aws_id}.${image_prefix}
  repo_list=$(${aws_cli} ecr describe-repositories --output text | awk '($1=="REPOSITORIES"){print $6}')
  for image in ${image_list[@]}; do
    repo_name=$(echo $image | cut -d: -f1)
    if ! $(echo ${repo_list} | grep -wq "${repo_name}"); then
      ${aws_cli} ecr create-repository --repository-name ${repo_name}
      ${aws_cli} ecr set-repository-policy --repository-name ${repo_name} --policy-text "${policy_json}"
    fi
      docker tag ${src_aws_id}.${image_prefix}/${image} ${dst_aws_id}.${image_prefix}/${image}
      docker push ${dst_aws_id}.${image_prefix}/${image}
  done
}

check_params $@
pull_ecr_images
push_ecr_images
