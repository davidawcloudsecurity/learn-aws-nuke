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

echo "aws-nuke has been installed successfully."
