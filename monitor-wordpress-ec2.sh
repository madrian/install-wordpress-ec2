#!/bin/bash
###############################################################################
# This script monitors the EC2 instance of WordPress
#
# 
###############################################################################

if [ $# -ne 1 ];then
    echo "Usage: `basename $0` instanceId"
    exit 1
fi
instance_id=$1


start_time=`date --iso-8601=seconds -d '1 hour ago'`
end_time=`date --iso-8601=seconds`

#TODO remove region
max_cpu=`aws cloudwatch get-metric-statistics \
    --metric-name CPUUtilization --namespace AWS/EC2 \
    --start-time $start_time --end-time $end_time \
    --period 3600 --statistics Maximum --region ap-southeast-1 \
    --dimensions Name=InstanceId,Value=$instance_id \
    --query 'Datapoints[0].Maximum' --output text`

response_status_json=`aws ec2 describe-instance-status \
    --instance-id $instance_id --region ap-southeast-1 \
instance_status=`echo $response_status_json | \
    jq '.InstanceStatuses[0].InstanceStatus.Status'`
system_status=`echo $response_status_json | \
    jq '.InstanceStatuses[0].SystemStatus.Status'`
instance_state=`echo $response_status_json | \
    jq '.InstanceStatuses[0].InstanceState.Name'

echo "Start time: $start_time"
echo "End time  : $end_time"
echo "Max CPU   : $max_cpu"
echo "Instance Status : $instance_status"
echo "System Status   : $system_status"
echo "Instance State  : $instance_state"
