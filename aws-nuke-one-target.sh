#!/bin/bash

# Function to display resource types
display_resource_types() {
    echo "Select a resource type to nuke:"
    aws-nuke resource-types | awk '{print NR". "$0}'
}

# Function to prompt user for input
prompt_for_input() {
    read -p "Enter the number corresponding to the resource type you want to nuke: " choice
    selected_resource=$(aws-nuke resource-types | awk "NR==$choice")
    echo "You selected: $selected_resource"
    aws-nuke -t $selected_resource -c config.yml --no-dry-run
}

# Main script
display_resource_types
prompt_for_input
