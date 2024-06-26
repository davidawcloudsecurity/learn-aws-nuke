#!/bin/bash

alias=$(aws iam list-account-aliases --query AccountAliases --output text)

# Function to display resource types
display_resource_types() {
    echo "Select a resource type to nuke (or type 'exit' to quit):"
    aws-nuke resource-types | awk '{print NR". "$0}'
}

# Function to prompt user for input
prompt_for_input() {
    read -p "Enter the number corresponding to the resource type you want to nuke (or type 'exit' to quit): " choice
    if [[ "$choice" == "exit" ]]; then
        echo "Exiting..."
        exit 0
    fi
    selected_resource=$(aws-nuke resource-types | awk "NR==$choice")
    if [[ -z "$selected_resource" ]]; then
        echo "Invalid choice. Please try again."
    else
        echo "You selected: $selected_resource"
    expect <<EOF
set timeout -1
spawn aws-nuke -t "$selected_resource" -c config.yml --no-dry-run
expect {
    "Do you really want to nuke the account with the ID*" {
        send "$alias\r"
        exp_continue
    }
    "Do you want to continue? Enter account alias to continue." {
        send "$alias\r"
        exp_continue
    }
    "Error*" {
        exit 0
    }
    eof
}
EOF
    fi
}

# Main script
while true; do
    display_resource_types
    prompt_for_input
    read -p "Enter to continue"
done
