#!/bin/bash

aws_cli="/usr/bin/aws"
image_prefix="dkr.ecr.us-west-1.amazonaws.com"
image_list=(
redis:latest
openjdk:8-jdk
)

function check_params(){
  if [ $# -ne 2 ]; then
    echo "Usage: ${0} src_aws_id dest_aws_id"
    echo "       ${0} 111111111111 222222222222"
    exit 1
  else
    src_aws_id=${1}
    dest_aws_id=${2}
  fi
}

function pull_ecr_images(){
  $(${aws_cli} ecr get-login --no-include-email --region us-west-1 --registry-ids $src_aws_id)
  for image in ${image_list[@]}; do
    docker pull ${src_aws_id}.${image_prefix}/${image}
  done
}

function push_ecr_images(){
  $(${aws_cli} ecr get-login --no-include-email --region us-west-1 --registry-ids $dest_aws_id)
  repo_list=$(${aws_cli} ecr describe-repositories --output text | awk '($1=="REPOSITORIES"){print $6}')
  for image in ${image_list[@]}; do
    repo_name=$(echo $image | cut -d: -f1)
    if ! $(echo ${repo_list} | grep -wq "${repo_name}"); then
      ${aws_cli} ecr create-repository --repository-name ${repo_name}
    fi
      docker tag ${src_aws_id}.${image_prefix}/${image} ${dest_aws_id}.${image_prefix}/${image}
      docker push ${dest_aws_id}.${image_prefix}/${image}
  done
}

check_params $@
pull_ecr_images
push_ecr_images
