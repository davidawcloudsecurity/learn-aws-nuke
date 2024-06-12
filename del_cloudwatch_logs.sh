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

# Function to delete all CloudWatch log groups
delete_log_groups() {
    # Get the list of all CloudWatch log groups
    echo "Fetching list of CloudWatch log groups..."
    log_groups=$(aws logs describe-log-groups --query 'logGroups[*].logGroupName' --output text)

    # Loop through each log group and delete it
    for log_group in $log_groups; do
        echo "Deleting log group: $log_group"
        aws logs delete-log-group --log-group-name "$log_group"
        echo "Log group $log_group has been deleted."
    done

    echo "All CloudWatch log groups have been deleted."
}

# Run the function to delete log groups
delete_log_groups
