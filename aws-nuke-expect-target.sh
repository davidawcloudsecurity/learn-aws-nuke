#!/bin/bash

# Function to install expect based on the OS type
install_expect() {
    if [[ "$os_type" == "Linux" ]]; then
        if command -v apt-get &> /dev/null; then
            echo "Detected Debian-based system. Installing expect using apt-get."
            sudo apt-get update
            sudo apt-get install -y expect
        elif command -v yum &> /dev/null; then
            echo "Detected Red Hat-based system. Installing expect using yum."
            sudo yum install -y expect
        elif command -v zypper &> /dev/null; then
            echo "Detected SUSE-based system. Installing expect using zypper."
            sudo zypper install -y expect
        else
            echo "Unsupported package manager. Please install expect manually."
            exit 1
        fi
    elif [[ "$os_type" == "Darwin" ]]; then
        echo "Detected macOS. Installing expect using brew."
        if command -v brew &> /dev/null; then
            brew install expect
        else
            echo "Homebrew is not installed. Please install Homebrew first: https://brew.sh/"
            exit 1
        fi
    else
        echo "Unsupported operating system. Please install expect manually."
        exit 1
    fi
}

# Detect the operating system
os_type=$(uname)

echo "Detected OS: $os_type"
install_expect

# Verify installation
if command -v expect &> /dev/null; then
    echo "Expect installed successfully."
else
    echo "Failed to install expect."
    exit 1
fi

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
set timeout -1
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
