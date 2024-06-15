#!/bin/bash

alias=$(aws iam list-account-aliases --query AccountAliases --output text)

# Function to display resource types and get the total number of resource types
get_resource_types() {
    aws-nuke resource-types > resource_types.txt
    total_resources=$(wc -l < resource_types.txt)
}

# Function to process each resource type
process_resource_type() {
    local resource_index=$1
    local resource_type=$(sed -n "${resource_index}p" resource_types.txt)
    echo "Processing resource type $resource_index: $resource_type"
    
    expect <<EOF
spawn aws-nuke -t "$resource_type" -c config.yml --no-dry-run
expect {
    "Do you really want to nuke the account with the ID*" {
        send "$alias\r"
        exp_continue
    }
    "Do you want to continue? Enter account alias to continue." {
        send "$alias\r"
        exp_continue
    }
    eof
}
EOF
}

# Main script
get_resource_types

for i in $(seq 1 $total_resources); do
    process_resource_type $i
done

# Clean up
rm resource_types.txt

echo "All resource types have been processed."
