#!/bin/bash

# Function to install AWS CLI if not found
install_awscli() {
    if ! command -v aws &> /dev/null; then
        echo "AWS CLI could not be found. Installing AWS CLI..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get update
            sudo apt-get install -y awscli
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install awscli
        else
            echo "Unsupported OS. Please install AWS CLI manually."
            exit 1
        fi
    else
        echo "AWS CLI is already installed."
    fi
}

# Install AWS CLI if not found
install_awscli

# Function to delete a subnet
delete_subnet() {
    subnet_id=$1
    echo "Deleting subnet: $subnet_id"
    aws ec2 delete-subnet --subnet-id $subnet_id
}

# Function to delete a route table
delete_route_table() {
    route_table_id=$1
    echo "Deleting route table: $route_table_id"
    aws ec2 delete-route-table --route-table-id $route_table_id
}

# Function to delete a security group
delete_security_group() {
    sg_id=$1
    echo "Deleting security group: $sg_id"
    aws ec2 delete-security-group --group-id $sg_id
}

# Function to delete a NAT gateway
delete_nat_gateway() {
    nat_gw_id=$1
    echo "Deleting NAT gateway: $nat_gw_id"
    aws ec2 delete-nat-gateway --nat-gateway-id $nat_gw_id
    aws ec2 wait nat-gateway-deleted --nat-gateway-ids $nat_gw_id
}

# Function to detach and delete an internet gateway
delete_internet_gateway() {
    igw_id=$1
    vpc_id=$2
    echo "Detaching internet gateway: $igw_id from VPC: $vpc_id"
    aws ec2 detach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id
    echo "Deleting internet gateway: $igw_id"
    aws ec2 delete-internet-gateway --internet-gateway-id $igw_id
}

# Function to delete the VPC
delete_vpc() {
    vpc_id=$1
    echo "Deleting VPC: $vpc_id"
    aws ec2 delete-vpc --vpc-id $vpc_id
}

# Get the list of all VPCs
echo "Fetching list of VPCs..."
VPCS=$(aws ec2 describe-vpcs --query "Vpcs[*].VpcId" --output text)

# Loop through each VPC
for VPC_ID in $VPCS; do
    echo "Processing VPC: $VPC_ID"
    
    # List and delete all subnets
    subnets=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].SubnetId" --output text)
    for subnet in $subnets; do
        delete_subnet $subnet
    done

    # List and delete all route tables
    route_tables=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query "RouteTables[*].RouteTableId" --output text)
    for route_table in $route_tables; do
        delete_route_table $route_table
    done

    # List and delete all security groups (excluding the default one)
    security_groups=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[?GroupName!='default'].GroupId" --output text)
    for sg in $security_groups; do
        delete_security_group $sg
    done

    # List and delete all NAT gateways
    nat_gateways=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query "NatGateways[*].NatGatewayId" --output text)
    for nat_gw in $nat_gateways; do
        delete_nat_gateway $nat_gw
    done

    # List and delete all internet gateways
    internet_gateways=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[*].InternetGatewayId" --output text)
    for igw in $internet_gateways; do
        delete_internet_gateway $igw $VPC_ID
    done

    # Finally, delete the VPC
    delete_vpc $VPC_ID

    echo "VPC $VPC_ID and its associated resources have been deleted."
done

echo "All VPCs and their associated resources have been deleted."
