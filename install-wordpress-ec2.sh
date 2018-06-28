#!/bin/bash
###############################################################################
# This script installs WordPress to a new AWS EC2 instance.
#
# 
###############################################################################

if [ $# -ne 1 ];then
    echo "Usage: `basename $0` keyName"
    exit 1
fi

# check the keypair
key_name=`aws ec2 describe-key-pairs --key-names $1 \
    --query 'KeyPairs[0].KeyName' --output text`
ret=$?
if [ $ret -ne 0 ];then
    echo "KeyName $1 not found."
    exit 1
else
    echo "Using KeyName $key_name"
fi

# use the security group wordpress-sg
security_group_name="wordpress-sg"
security_group_id=`aws ec2 describe-security-groups \
    --group-names $security_group_name \
    --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null`
ret=$?
if [ $ret -ne 0 ];then
    echo "Creating security group $security_group_name ..."
    security_group_id=`aws ec2 create-security-group \
        --group-name $security_group_name \
        --description "wordpress-security-group" \
        --query 'GroupId' --output text`
    # allow incoming http and ssh traffic
    # allow from all for simplicity, restrict cidr block
    aws ec2 authorize-security-group-ingress \
        --group-id $security_group_id \
        --protocol tcp --port 80 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress \
        --group-id $security_group_id \
        --protocol tcp --port 22 --cidr 0.0.0.0/0
fi

echo "Creating the EC2 instance ..."
instance_id=`aws ec2 run-instances --image-id ami-de90a5a2 \
    --count 1 --instance-type t2.micro \
    --key-name $key_name --security-group-ids $security_group_id \
    --query 'Instances[0].InstanceId' --output text \
    --user-data file://wp-userdata.txt`
echo "instanceId=$instance_id"

# wait for the instance to be in ok status
echo "Installing WordPress on the EC2 instance, this might take a few minutes ..."
aws ec2 wait instance-status-ok --instance-id $instance_id

instance_url=`aws ec2 describe-instances --instance-id $instance_id \
    --query 'Reservations[0].Instances[0].PublicDnsName' --output text`
echo "Your WordPress blog is ready!"
echo "Go to http://$instance_url/blog"
