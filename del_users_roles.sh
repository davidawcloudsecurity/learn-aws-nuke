#!/bin/bash

# Step 1: List IAM users and roles
USERS=$(aws iam list-users --query 'Users[*].UserName' --output text)
ROLES=$(aws iam list-roles --query 'Roles[*].RoleName' --output text)

# Step 2: Loop through and delete IAM users
for USER in $USERS; do
    echo "Detaching policies for IAM user: $USER"
    
    # Step 2.1: List attached policies
    POLICIES=$(aws iam list-attached-user-policies --user-name $USER --query 'AttachedPolicies[*].PolicyArn' --output text)
    
    # Step 2.2: Detach each policy
    for POLICY in $POLICIES; do
        echo "Detaching policy: $POLICY from IAM user: $USER"
        aws iam detach-user-policy --user-name $USER --policy-arn $POLICY
    done
    
    # Step 2.3: List and detach inline policies
    INLINE_POLICIES=$(aws iam list-user-policies --user-name $USER --query 'PolicyNames[*]' --output text)
    
    for INLINE_POLICY in $INLINE_POLICIES; do
        echo "Deleting inline policy: $INLINE_POLICY for IAM user: $USER"
        aws iam delete-user-policy --user-name $USER --policy-name $INLINE_POLICY
    done

    # Step 2.4: Delete IAM user
    echo "Deleting IAM user: $USER"
    aws iam delete-user --user-name $USER
done

# Step 3: Loop through and delete IAM roles
for ROLE in $ROLES; do
    echo "Detaching policies for IAM role: $ROLE"
    
    # Step 3.1: List attached policies
    POLICIES=$(aws iam list-attached-role-policies --role-name $ROLE --query 'AttachedPolicies[*].PolicyArn' --output text)
    
    # Step 3.2: Detach each policy
    for POLICY in $POLICIES; do
        echo "Detaching policy: $POLICY from IAM role: $ROLE"
        aws iam detach-role-policy --role-name $ROLE --policy-arn $POLICY
    done
    
    # Step 3.3: List and detach inline policies
    INLINE_POLICIES=$(aws iam list-role-policies --role-name $ROLE --query 'PolicyNames[*]' --output text)
    
    for INLINE_POLICY in $INLINE_POLICIES; do
        echo "Deleting inline policy: $INLINE_POLICY for IAM role: $ROLE"
        aws iam delete-role-policy --role-name $ROLE --policy-name $INLINE_POLICY
    done

    # Step 3.4: Delete IAM role
    echo "Deleting IAM role: $ROLE"
    aws iam delete-role --role-name $ROLE
done

echo "All IAM users, roles, and their associated policies have been deleted."
