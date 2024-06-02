#!/bin/bash

# Function to check if AWS CLI is installed
function check_aws_cli_installed {
    if ! command -v aws &> /dev/null; then
        echo "AWS CLI could not be found, please install it first."
        exit 1
    fi
}

# Function to delete EC2 instances
function delete_ec2_instances {
    echo "Deleting all EC2 instances..."
    instance_ids=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --output text)
    if [ -n "$instance_ids" ]; then
        aws ec2 terminate-instances --instance-ids $instance_ids
        echo "Waiting for instances to terminate..."
        aws ec2 wait instance-terminated --instance-ids $instance_ids
        if [ $? -eq 0 ]; then
            echo "All EC2 instances deleted."
        else
            echo "Failed to delete EC2 instances."
            return 1
        fi
    else
        echo "No EC2 instances found."
    fi
    return 0
}

# Function to delete S3 buckets
function delete_s3_buckets {
    echo "Deleting all S3 buckets..."
    buckets=$(aws s3api list-buckets --query 'Buckets[*].Name' --output text)
    for bucket in $buckets; do
        echo "Deleting bucket $bucket..."
        aws s3 rm s3://$bucket --recursive
        aws s3api delete-bucket --bucket $bucket
        if [ $? -eq 0 ]; then
            echo "Bucket $bucket deleted."
        else
            echo "Failed to delete bucket $bucket."
            return 1
        fi
    done
    echo "All S3 buckets deleted."
    return 0
}

# Function to delete Transit Gateway attachments
function delete_tgw_attachments {
    echo "Deleting all Transit Gateway Attachments..."
    attachments=$(aws ec2 describe-transit-gateway-attachments --query 'TransitGatewayAttachments[*].TransitGatewayAttachmentId' --output text)
    for attachment in $attachments; do
        echo "Deleting Transit Gateway Attachment $attachment..."
        aws ec2 delete-transit-gateway-vpc-attachment --transit-gateway-attachment-id $attachment
        if [ $? -eq 0 ]; then
            echo "Attachment $attachment deleted."
        else
            echo "Failed to delete attachment $attachment. It might have dependencies or already be deleted."
            return 1
        fi
    done
    echo "All Transit Gateway Attachments deleted."
    return 0
}

# Function to delete Transit Gateways
function delete_transit_gateways {
    echo "Deleting all Transit Gateways..."
    transit_gateways=$(aws ec2 describe-transit-gateways --query 'TransitGateways[*].TransitGatewayId' --output text)
    for tg in $transit_gateways; do
        echo "Checking attachments for Transit Gateway $tg..."
        attachments=$(aws ec2 describe-transit-gateway-attachments --filters Name=transit-gateway-id,Values=$tg --query 'TransitGatewayAttachments[?State!=`deleted`].TransitGatewayAttachmentId' --output text)
        if [ -z "$attachments" ]; then
            echo "Deleting Transit Gateway $tg..."
            aws ec2 delete-transit-gateway --transit-gateway-id $tg
            if [ $? -eq 0 ]; then
                echo "Transit Gateway $tg deleted."
            else
                echo "Failed to delete Transit Gateway $tg. It might have dependencies."
                return 1
            fi
        else
            echo "Transit Gateway $tg has non-deleted attachments: $attachments"
            return 1
        fi
    done
    echo "All Transit Gateways deleted."
    return 0
}

# Main script execution
check_aws_cli_installed

# Confirm deletion
read -p "Are you sure you want to delete all EC2 instances, S3 buckets, Transit Gateways, and their attachments in your AWS account? (yes/no): " confirmation
if [ "$confirmation" != "yes" ]; then
    echo "Aborting deletion."
    exit 0
fi

# Perform deletions and track success
delete_ec2_instances
ec2_result=$?

delete_s3_buckets
s3_result=$?

delete_tgw_attachments
tgw_attachments_result=$?

delete_transit_gateways
tg_result=$?

# Summary
if [ $ec2_result -eq 0 ] && [ $s3_result -eq 0 ] && [ $tgw_attachments_result -eq 0 ] && [ $tg_result -eq 0 ]; then
    echo "All specified resources have been successfully deleted."
else
    echo "Failed to delete some resources:"
    if [ $ec2_result -ne 0 ]; then echo " - EC2 instances"; fi
    if [ $s3_result -ne 0 ]; then echo " - S3 buckets"; fi
    if [ $tgw_attachments_result -ne 0 ]; then echo " - Transit Gateway attachments"; fi
    if [ $tg_result -ne 0 ]; then echo " - Transit Gateways"; fi
fi
