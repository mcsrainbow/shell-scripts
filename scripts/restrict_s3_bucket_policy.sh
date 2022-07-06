#!/bin/bash

# Apply a S3 bucket policy to each S3 bucket
# To limit the access only from specific VPCs and ARNs and SourceIPs
# By Damon Guo at 20220706

aws_cli="/usr/local/bin/aws"
policy_json_data='
{
    "Version": "2012-10-17",
    "Id": "Restrict VPCs and ARNs and SourceIPs",
    "Statement": [
        {
            "Sid": "VPCs and ARNs and SourceIPs",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::BUCKET_NAME",
                "arn:aws:s3:::BUCKET_NAME/*"
            ],
            "Condition": {
                "Bool": {
                    "aws:ViaAWSService": "false"
                },            
                "StringNotEqualsIfExists": {
                    "aws:SourceVpc": [
                        "vpc-857abc857abc875aa",
                        "vpc-857cba857cba875bb"
                    ]
                },
                "ArnNotLikeIfExists": {
                    "aws:PrincipalArn": [
                        "arn:aws:iam::857857857857:role/YourRoleName",
                        "arn:aws:iam::361361361361:role/YourRoleName",
                        "arn:aws:iam::857857857857:role/Role*",
                        "arn:aws:iam::361361361361:role/Role*"
                    ]
                },
                "NotIpAddressIfExists": {
                    "aws:SourceIp": [
                        "8.5.7.11/32",
                        "8.5.7.22/32"
                    ]
                }
            }
        }
    ]
}
'

bucket_list=$(${aws_cli} s3 ls | awk '{print $NF}' | grep -E '^heylinux|damonguo')
for bucket in ${bucket_list}; do
  echo "Updating the bucket policy of s3://${bucket} ..."
  echo ${policy_json_data} | sed s/BUCKET_NAME/${bucket}/g > /tmp/bucket_policy.json
  ${aws_cli} s3api put-bucket-policy --bucket ${bucket} --policy file:///tmp/bucket_policy.json
done
