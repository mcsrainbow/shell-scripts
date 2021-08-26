#!/bin/bash

# Applies S3 bucket policy to the S3 buckets which have specific tags
# To limit the access as only from specific VPCs and RoleArns and SourceIPs

aws_cli="/usr/bin/aws"
policy_json_data='
{
    "Version": "2012-10-17",
    "Id": "VPCs and RoleArns and SourceIPs",
    "Statement": [
        {
            "Sid": "VPCs and SourceIPs",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::BUCKET_NAME",
                "arn:aws:s3:::BUCKET_NAME/*"
            ],
            "Condition": {
                "ForAllValues:StringNotEquals": {
                    "aws:SourceVpc": [
                        "vpc-xxxxxxxxxxxxxxxxa",
                        "vpc-xxxxxxxxxxxxxxxxb"
                    ]
                },
                "ForAllValues:ArnNotLike": {
                    "aws:PrincipalArn": [
                        "arn:aws:iam::xxxxxxxxxxxa:role/XxxxXxxc",
                        "arn:aws:iam::xxxxxxxxxxxb:role/XxxxXxxc",
                        "arn:aws:iam::xxxxxxxxxxxa:role/*Xxxd*",
                        "arn:aws:iam::xxxxxxxxxxxb:role/*Xxxd*
                    ]
                },
                "ForAllValues:NotIpAddress": {
                    "aws:SourceIp": [
                        "1.1.1.1/32",
                        "1.1.1.2/32"
                    ]
                }
            }
        }
    ]
}
'

bucket_list=$(${aws_cli} s3 ls | awk '{print $NF}')
for bucket in ${bucket_list}; do
  if $(${aws_cli} s3api get-bucket-tagging --bucket ${bucket} 2>/dev/null | grep -w "Xxxx" -A1 | grep -Ewq "Xxxa|Xxxb"); then
    echo "Updating the bucket policy of s3://${bucket} ..."
    echo ${policy_json_data} | sed s/BUCKET_NAME/${bucket}/g > /tmp/bucket_policy.json
    ${aws_cli} s3api put-bucket-policy --bucket ${bucket} --policy file:///tmp/bucket_policy.json
  fi
done
