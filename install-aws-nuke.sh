#!/bin/bash

# Prompt the user for the URL
read -p "Enter the URL for the aws-nuke tarball: " url

# Check if the URL is not empty
if [ -z "$url" ]; then
  echo "URL cannot be empty. Exiting."
  exit 1
fi

# Download the aws-nuke tarball
wget -c "$url" -O aws-nuke.tar.gz

# Extract the aws-nuke binary
tar -xvf aws-nuke.tar.gz

# Find the extracted binary (assuming it's the only file in the tarball)
binary_name=$(tar -tf aws-nuke.tar.gz | head -n 1)

# Rename the extracted binary to aws-nuke
mv "$binary_name" aws-nuke

# Copy the extracted binary to your $PATH
sudo mv aws-nuke /usr/local/bin/aws-nuke

# Clean up
rm aws-nuke.tar.gz

# Retrieve the current AWS account ID using AWS CLI
account_id=$(aws sts get-caller-identity --query Account --output text)

# Retrieve the current AWS region
current_region=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')

# Prompt the user for the IAM user name
read -p "Enter the IAM user name to exclude from deletion: " iam_user_name

# Initialize IAM user filters
iam_user_filter=""
iam_user_policy_attachment_filter=""
formatted_roles=""

# If IAM user name is provided, set the IAM user filters
if [ -n "$iam_user_name" ]; then
    # Get the attached policies for the IAM user
    policies=$(aws iam list-attached-user-policies --user-name "$iam_user_name" --query 'AttachedPolicies[*].PolicyName' --output text)
    
    # Format the IAM user filters
    iam_user_filter="      IAMUser:\n      - \"$iam_user_name\""
    iam_user_policy_attachment_filter="      IAMUserPolicyAttachment:\n      - \"$iam_user_name -> AdministratorAccess\""
    
    # Format policies as array items in YAML
    formatted_policies=$(echo "$policies" | tr ' ' '\n' | sed 's/^/        - "/' | sed 's/$/"/')
else
    # Prompt the user for the IAM role name
    read -p "Enter the IAM role to exclude from deletion: " iam_role_name
    # Format the role as array items in YAML
    formatted_roles=$(echo $iam_role_name | tr ' ' '\n' | sed 's/^/      - "/' | sed 's/$/"/')
fi

# Create the YAML configuration file with the retrieved account ID and region
{
echo "regions:"
echo "- $current_region"
echo
echo "account-blocklist:"
echo "- \"999999999999\" # production"
echo
echo "accounts:"
echo "  \"$account_id\": # aws-nuke-example"
echo "    filters:"
if [ -n "$iam_user_filter" ]; then
    echo -e "$iam_user_filter"
fi
if [ -n "$iam_user_policy_attachment_filter" ]; then
    echo -e "$iam_user_policy_attachment_filter"
fi
echo "      IAMRole:"
if [ -n "$formatted_roles" ]; then
    echo "$formatted_roles"
fi
} > config.yml

# Remove any extra newlines
sed -i '/^ *$/d' config.yml

echo "aws-nuke has been installed successfully."
echo "Configuration file config.yml has been created."
echo "vi or nano config.yml to filter or add user or role not to be deleted."
echo "Run the following commands to execute aws-nuke"
echo "aws-nuke -c config.yml --no-dry-run"
