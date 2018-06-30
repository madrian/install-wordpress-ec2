# WordPress installer on EC2
A simple bash script that installs [WordPress][wordpress] on a new EC2 instance.

# Pre-requisites
  * AWS EC2 account
  * [AWS cli][aws-cli] installed
    * with credentials setup
> e.g.  
> aws_secret_access_key = abc123  
> aws_access_key_id = 456789  
    * with region set in the config
> e.g.  
> region = ap-southeast-1  
  * Bash shell
  * [jq][jq-download] installed
    * This is needed to parse the json response of AWS cli.

# Installer
## Usage
```console
install-wordpress-ec2.sh keyName
```
## Execution steps
  1. The **keyName** to access the instance is required. If you don't have one yet, check out the AWS EC2 documentation on how to [create a key pair][aws-create-key-pair].
  1. A security group named **wordpress-sg** is created if it doesn't exists. It allows access to SSH and HTTP ports 22 and 80, respectively. 
  1. A **t2.micro** instance is created using **Amazon Linux** (image-id=ami-de90a5a2).
  1. The script will wait for the instance creation until it is in the *running* state.
  1. The script will then poll the blog's url until it receives a **http code 200** success response.
  1. The blog's url will be displayed at the end.

## Sample output
```console
$ ./install-wordpress-ec2.sh madrian-keypair
Using KeyName madrian-keypair
Creating the EC2 instance ...
Instance created and running.
> instanceId=i-0c2122863cc167f53
Installing WordPress on the EC2 instance, this might take a few minutes ...
...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......  [OK]
Your WordPress blog is ready!
Go to http://ec2-54-179-135-255.ap-southeast-1.compute.amazonaws.com/blog
```

# Monitor script
A simple monitoring script is added to see the health status of the EC2 instance and the WordPress installation.

## Usage
```console
monitor-wordpress-ec2.sh instanceId
```
> Pass here the instanceId returned by the installer script.

## Metrics and states monitored
The script will query the following:

  1. The EC2 metric **CPUUtilization** from **AWS CloudWatch** reporting the maximum CPU percentage reached in the last one hour.
  1. The different EC2 instance states including the instance status, system status, and the instance state *pending*, *running*, etc.
  1. The blog's url and its underlying *PHP* server's availability whether they are *UP* or *DOWN*

## Sample output
```console
$ ./monitor-wordpress-ec2.sh i-0c2122863cc167f53
-------------------------------------------------------------------------------
Start time       : 2018-06-30T12:07:49+08:00
End time         : 2018-06-30T13:07:49+08:00
Max CPU          : 70.5084745762712
-------------------------------------------------------------------------------
Instance status  : "ok"
System status    : "ok"
Instance state   : "running"
-------------------------------------------------------------------------------
Blog URL         : http://ec2-54-179-135-255.ap-southeast-1.compute.amazonaws.com/blog
PHP site status  : UP
Blog site status : UP
-------------------------------------------------------------------------------
```

[wordpress]: https://wordpress.org
[aws-cli]: https://aws.amazon.com/cli
[jq-download]: https://stedolan.github.io/jq/download/
[aws-create-key-pair]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair
