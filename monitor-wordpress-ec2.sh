#!/bin/bash
###############################################################################
# This script monitors WordPress on an EC2 instance.
# 
#
# Author: Adrian
# GitHub: https://github.com/madrian/install-wordpress-ec2 
###############################################################################

# checks the urls connectivity with 15 sec timeout
health_check() {
    http_code=`curl --max-time 15 $1 -w "%{http_code}" -o /dev/null -s -L`
    if [ $http_code -eq 200 ]; then
        health_check_status="UP"
        return 0
    else
        health_check_status="DOWN"
        return 1
    fi
}

if [ $# -ne 1 ]; then
    echo "Usage: `basename $0` instanceId"
    exit 1
fi
instance_id=$1


start_time=`date --iso-8601=seconds -d '1 hour ago'`
end_time=`date --iso-8601=seconds`

# check instance metrics
max_cpu=`aws cloudwatch get-metric-statistics \
    --metric-name CPUUtilization --namespace AWS/EC2 \
    --start-time $start_time --end-time $end_time \
    --period 3600 --statistics Maximum \
    --dimensions Name=InstanceId,Value=$instance_id \
    --query 'Datapoints[0].Maximum' --output text`

# check instance statuses
response_status_json=`aws ec2 describe-instance-status \
    --instance-id $instance_id`
instance_status=`echo $response_status_json | \
    jq '.InstanceStatuses[0].InstanceStatus.Status'`
system_status=`echo $response_status_json | \
    jq '.InstanceStatuses[0].SystemStatus.Status'`
instance_state=`echo $response_status_json | \
    jq '.InstanceStatuses[0].InstanceState.Name'`

# check wordpress site health
instance_url=`aws ec2 describe-instances --instance-id $instance_id \
    --query 'Reservations[0].Instances[0].PublicDnsName' --output text`

php_url=$instance_url/phpinfo.php
health_check $php_url
ret=$?
php_health=$health_check_status
blog_url=$instance_url/blog
if [ $ret -eq 0 ]; then
    # check blog only if php is up
    health_check $blog_url
fi
blog_health=$health_check_status


cat <<EOF
-------------------------------------------------------------------------------
Start time       : $start_time
End time         : $end_time
Max CPU          : $max_cpu
-------------------------------------------------------------------------------
Instance status  : $instance_status
System status    : $system_status
Instance state   : $instance_state
-------------------------------------------------------------------------------
Blog URL         : http://$blog_url
PHP site status  : $php_health
Blog site status : $blog_health
-------------------------------------------------------------------------------
EOF
