#!/bin/bash
# To get basic information on your instance using AWS API Key to get Instance Runing Status, Public IP and ID also based from that information you can start and stop your instance.
# Requires only AWS CLI to be installed.
# Author: Mayur Chavhan
# Usage: ./aws-shell-console.sh

set -euo pipefail

function printBOX () {
    printf "\n"
    msg="$*"
    bdr=$(echo "$msg" | sed 's/./@/g')
    echo "$bdr"
    echo "$msg"
    echo "$bdr"
    printf "\n"
}

if ! [ -x "$(command -v aws)" ]; then
  printf "\n"
  echo '[ ❌ ] Error: AWS CLI is not installed.' >&2
  exit 1
fi


function check_instance_id () {
    
    if echo "$1" | grep -E '^i-[a-zA-Z0-9]{8,}' > /dev/null; then 
        echo "[ ✅ ] Valid Instance ID"
        return 0
    else 
        echo "[ ❌ ] ERROR: Wrong Instance ID, Please Check and Try Again."
        return 1
    fi
}

function check_instance_status () {
    
    while true; do
        status=$(aws ec2 describe-instances --instance-ids "$1" --query 'Reservations[*].Instances[*].State.Name' --output text)
        if [ "$status" = "running" ]; then
            echo "[ ✅ ] Instance is running"
            break
        elif [ "$status" = "pending" ]; then
            echo "[ 🚧 ] Instance is starting..."
            sleep 5
        elif [ "$status" = "stopping" ]; then
            echo "[ 🚧 ] Instance is stopping..."
            sleep 20
        else [ "$status" = "stopped" ];
            echo "[ ✅ ] Instance is stopped !!"
            break
        fi
    done
}


printf "\n" 
read -p "[ 🚀 ] Please enter your NAME / HOSTNAME to get your instance info: " your_name
printf "\n" 
W_msg=$(echo -e " \t \e[7;101;1;92m  Hi $your_name \e[5;47;1;35m Welcome to AWS Shell Console \e[0m \t")

printBOX "$W_msg"

if ! [ -d ~/.aws ] && [ -f ~/.aws/credentials ]; then

mkdir ~/.aws

echo '[Error]: AWS CLI Credentials File Does not Exist.' >&2
read -p "[ ⭐ ] Enter your AWS Access Key ID    : " access_key
printf "\n"
read -p "[ ⭐ ] Enter your AWS Secret Access Key: " secret_key
printf "\n"
read -p "[ 🌏 ] Enter your AWS Region           : " aws_region
printf "\n"


cat << EOF > ~/.aws/credentials
[default]
aws_access_key_id = ${access_key}
aws_secret_access_key = ${secret_key}
EOF

cat << EOF > ~/.aws/config
[default]
region = ${aws_region}
EOF

fi

function your_InstanceInfo() {
    aws ec2 describe-instances --query "Reservations[*].Instances[*].{PublicIP:PublicIpAddress,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,InstanceId:InstanceId}" --filters Name=tag:Name,Values="*${your_name:-*}*" --output table
}

function list_rds_instances () {
    aws rds describe-db-instances --query 'DBInstances[*].DBInstanceIdentifier' --output table
} 

function get_rds_instance_info () {
    printf "\n"
    aws rds describe-db-instances --db-instance-identifier "${rds_instance_id:-$your_name}" --query 'DBInstances[*].{DBInstanceIdentifier:DBInstanceIdentifier,DBInstanceStatus:DBInstanceStatus,DBInstanceClass:DBInstanceClass,DBInstanceStorageType:DBInstanceStorageType,AllocatedStorage:AllocatedStorage,Endpoint:Endpoint.Address,Port:Endpoint.Port,MultiAZ:MultiAZ,Engine:Engine,EngineVersion:EngineVersion,DBInstanceIdentifier:DBInstanceIdentifier,DBInstanceStatus:DBInstanceStatus,DBInstanceClass:DBInstanceClass,DBInstanceStorageType:DBInstanceStorageType,AllocatedStorage:AllocatedStorage,Endpoint:Endpoint.Address,Port:Endpoint.Port,MultiAZ:MultiAZ,Engine:Engine,EngineVersion:EngineVersion}' --output table
}


function check_rds_instance_status () {
    while true; do
        status=$(aws rds describe-db-instances --db-instance-identifier "$1" --query 'DBInstances[*].DBInstanceStatus' --output text)
        if [ "$status" = "available" ]; then
            echo "[ ✅ ] RDS Instance is available"
            break
        elif [ "$status" = "stopping" ]; then
            echo "[ 🚧 ] RDS Instance is stopping..."
            sleep 50
        elif [ "$status" = "stopped" ]; then
            echo "[ ✅ ] RDS Instance is stopped !!"
            break
        else [ "$status" = "starting" ];
            echo "[ 🚧 ] RDS Instance is starting..."
            sleep 40
        fi
    done
}

function stop_EC2_Instance() {
    printf "\n"  
    printf "\033[31;5m\e[4;103;1;91m [WARNING] \033[0m\e[4;40;1;91m Please check and verify your instance name and status before you proceed to stop an Instance\033[0m\n"
    your_InstanceInfo
    printf "\n"
    read -p "[ 🆔 ] Enter AWS EC2 INSTANCE ID   : " instance_id
    check_instance_id "${instance_id}"
    check_instance_status "${instance_id}"
    read -p "[ ❗ ] Do you want to stop instance ${instance_id} ? (y/n)  : " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]];  then
        printf "\n[ ⌛ ] Please wait while instance is stopping...\n"
        aws ec2 stop-instances --instance-ids ${instance_id} >> /dev/null
        check_instance_status "${instance_id}"
    fi

    read -p "[ ❗ ] Do you want to stop an another instance ? (y/n)  : " -n 1 -r
    printf "\n"
    if [[ $REPLY =~ ^[Yy]$ ]];  then
        your_InstanceInfo
        printf "\n"
        read -p "[ ✅ ] Enter AWS EC2 INSTANCE ID   : " instance_id
        check_instance_id "${instance_id}"
        check_instance_status "${instance_id}"
    fi    
}

function start_EC2_Instance() {
    printf "\n"  
    your_InstanceInfo
    printf "\n"
    read -p "[ 🆔 ] Enter AWS EC2 INSTANCE ID   : " instance_id
    check_instance_id "${instance_id}"
    check_instance_status "${instance_id}"
    read -p "[ ❗ ] Do you want to start an instance [ ${instance_id} ] ? (y/n)  : " -n 1 -r
    printf "\n"
    if [[ $REPLY =~ ^[Yy]$ ]];  then
        printf "\n[ ⌛ ] Please wait while instance is starting...\n"
        aws ec2 start-instances --instance-ids ${instance_id} >> /dev/null
        check_instance_status "${instance_id}"
    fi

    read -p "[ ❗ ] Do you want to start an another instance ? (y/n)  : " -n 1 -r
    printf "\n"
    if [[ $REPLY =~ ^[Yy]$ ]];  then
        your_InstanceInfo
        printf "\n"
        read -p "[ ✅ ] Enter AWS EC2 INSTANCE IidentifierD   : " instance_id
        read -p "[ ❗ ] Do you want to start an instance ${instance_id}? (y/n)  : " -n 1 -r
        printf "\n"
        if [[ $REPLY =~ ^[Yy]$ ]];  then
            printf "\n[ ⌛ ] Please wait while instance is starting...\n"
            aws ec2 start-instances --instance-ids ${instance_id} >> /dev/null
            check_instance_status "${instance_id}"
            wait
        fi

    fi    
}

function stop_RDS_Instance() {
    printf "\n"  
    get_rds_instance_info
    printf "\n"
    read -p "[ 🆔 ] Enter AWS RDS DB identifier      : " rds_instance_id
    read -p "[ 🌏 ] Enter AWS RDS Region [us-east-1] : " rds_region
    read -p "[ ❗ ] Do you want to stop RDS instance ${rds_instance_id}? (y/n)  : " -n 1 -r
    printf "\n"
    if [[ $REPLY =~ ^[Yy]$ ]];  then
        printf "\n[ ⌛ ] Please wait while instance is stopping...\n"
        aws rds stop-db-instance --db-instance-identifier "$rds_instance_id" --region $rds_region >> /dev/null
        check_rds_instance_status "${rds_instance_id}"
        wait
    fi

    read -p "[ ❗ ] Do you want to stop an another RDS instance ? (y/n)  : " -n 1 -r
    printf "\n"
    if [[ $REPLY =~ ^[Yy]$ ]];  then
        get_rds_instance_info
        printf "\n"
        read -p "[ ✅ ] Enter AWS RDS INSTANCE Identifier   : " rds_instance_id
        read -p "[ ❗ ] Do you want to stop an instance ${rds_instance_id}? (y/n)  : " -n 1 -r
        printf "\n"
        if [[ $REPLY =~ ^[Yy]$ ]];  then
            printf "\n[ ⌛ ] Please wait while instance is stopping...\n"
            aws rds stop-db-instance --db-instance-identifier "$rds_instance_id" --region $rds_region >> /dev/null
            check_rds_instance_status "${rds_instance_id}"
            wait
        fi

    fi    
}

function start_RDS_Instance() {
    printf "\n"  
    get_rds_instance_info
    printf "\n"
    read -p "[ 🆔 ] Enter AWS RDS DB identifier      : " rds_instance_id
    read -p "[ 🌏 ] Enter AWS RDS Region [us-east-1] : " rds_region
    read -p "[ ❗ ] Do you want to start RDS instance ${rds_instance_id}? (y/n)  : " -n 1 -r
    printf "\n"
    if [[ $REPLY =~ ^[Yy]$ ]];  then
        printf "\n[ ⌛ ] Please wait while instance is starting...\n"
        aws rds start-db-instance --db-instance-identifier "$rds_instance_id" --query 'DBInstance.DBInstanceIdentifier' --region ${rds_region} >> /dev/null
        check_rds_instance_status "${rds_instance_id}"
        wait
    fi

    read -p "[ ❗ ] Do you want to start an another instance ? (y/n)  : " -n 1 -r
    printf "\n"
    if [[ $REPLY =~ ^[Yy]$ ]];  then
        get_rds_instance_info
        printf "\n"
        read -p "[ ✅ ] Enter AWS RDS INSTANCE IidentifierD   : " rds_instance_id
        read -p "[ ❗ ] Do you want to start an instance ${rds_instance_id}? (y/n)  : " -n 1 -r
        printf "\n"
        if [[ $REPLY =~ ^[Yy]$ ]];  then
            printf "\n[ ⌛ ] Please wait while instance is starting...\n"
            aws rds start-db-instance --db-instance-identifier "$rds_instance_id" --query 'DBInstance.DBInstanceIdentifier' --region ${rds_region:-us-east-1} >> /dev/null
            check_rds_instance_status "${rds_instance_id}"
            wait
        fi

    fi    
}


PS3="⭕ Choose an option  ▶▶ "
select option in "GET EC2 Instance INFO" "STOP EC2 Instance" "START EC2 Instance" "List All RDS Instances" "GET Your RDS Instance INFO" "STOP RDS Instance" "START RDS INSTANCE" "Install CRON to stop instance" "Exit"; do
    case $option in
        "GET EC2 Instance INFO")
            your_InstanceInfo
            ;;
        "STOP EC2 Instance")
            stop_EC2_Instance
            ;;
        "START EC2 Instance")
            start_EC2_Instance
            ;;
        "List All RDS Instances")
            list_rds_instances
            ;;
        "GET Your RDS Instance INFO")
            get_rds_instance_info
            ;;
        "STOP RDS Instance")
            stop_RDS_Instance
            ;;
        "START RDS INSTANCE")
            start_RDS_Instance
            ;;
        "Install CRON to stop instances")
            echo -e "\n Coming Soon... \n"
            ;;
        Exit)
            printBOX " Bye ✌ "
            exit 0
            ;;
        *) echo "Invalid option $REPLY";;
    esac
done
