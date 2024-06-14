#!/bin/bash

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
        aws-nuke -t "$selected_resource" -c config.yml --no-dry-run
    fi
}

# Main script
while true; do
    display_resource_types
    prompt_for_input
    read -p "Enter to continue"
done
