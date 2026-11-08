#!/bin/bash

SG_ID="sg-046c1f5818bea5c05"
AMI_ID="ami-0055977a6e828a4f4"
ZONE_ID="Z01032422UQPZQPC0HZ2Q"
DOMAIN_NAME="shannu.online"

for instance in "$@"
do 

INSTANCE_ID=$( aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type t3.micro \
    --security-group-ids "$SG_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text
      )
# echo "Instance Name and ID : "$instance", "$INSTANCE_ID"" 

        if [ "$instance" == "frontend" ]; then
                    IP=$( aws ec2 describe-instances \
                    --instance-ids "$INSTANCE_ID" \
                    --query "Reservations[].Instances[].PublicIpAddress" \
                    --output text          
                    )
                    
            RECORD_NAME="$DOMAIN_NAME"     #shannu.online    
        else 
                IP=$( aws ec2 describe-instances \
                --instance-ids "$INSTANCE_ID" \
                --query "Reservations[].Instances[].PrivateIpAddress" \
                --output text
                )
             
             RECORD_NAME="$instance.$DOMAIN_NAME"    #mongodb.shannu.online
         
        fi            
        echo "IP Address :$IP"

          aws route53 change-resource-record-sets \
            --hosted-zone-id "$ZONE_ID" \
            --change-batch '{
              "Comment": "Updating record",
              "Changes": [ {
                        "Action": "UPSERT",
                        "ResourceRecordSet": {
                        "Name":"'$RECORD_NAME'",
                        "Type": "A",
                        "TTL": 1,
                        "ResourceRecords": [
                                {
                                 "Value": "'$IP'"
                        }
                     ]
                  }
                }
              ]
            }'
        
         echo "Instance Name Record & IP : "$instance"-> "$RECORD_NAME"  "$IP""
        
done
