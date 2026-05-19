#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-0e0623cb2d0a1a386"
ZONE_ID="Z0277344SGE3U6H4KTFH"
DOMAIN_ID="dawshfs.fun"

for instance in "$@"
do
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --count 1 \
        --instance-type t3.micro \
        --security-group-ids "$SG_ID" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query 'Instances[0].InstanceId' \
        --output text)

    if [ "$instance" != "frontend" ]; then
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text)
            RECORD_NAME="$instance.$DOMAIN_ID"
    else
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)
            RECORD_NAME="$DOMAIN_ID"
    fi

    echo "$instance: $IP"
    echo "Creating Route53 record: $RECORD_NAME"

     aws route53 change-resource-record-sets \
        --hosted-zone-id $ZONE_ID \
        --change-batch '
    {
        "Comment": "Updating record set"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$RECORD_NAME'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$IP'"
            }]
        }
        }]
    }
    '

    echo "DNS record created"
    echo "-----------------------------"

done