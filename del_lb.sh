#!/bin/bash

# Step 1: Get Load Balancer ARNs
LOAD_BALANCER_ARNS=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[*].LoadBalancerArn' --output text)

# Loop through each load balancer ARN
for LOAD_BALANCER_ARN in $LOAD_BALANCER_ARNS; do
    echo "Processing Load Balancer ARN: $LOAD_BALANCER_ARN"

    # Step 1.1: Disable deletion protection
    echo "Disabling deletion protection for Load Balancer ARN: $LOAD_BALANCER_ARN"
    aws elbv2 modify-load-balancer-attributes \
      --load-balancer-arn $LOAD_BALANCER_ARN \
      --attributes Key=deletion_protection.enabled,Value=false

    # Step 2: List listeners for the current load balancer
    listeners=$(aws elbv2 describe-listeners --load-balancer-arn $LOAD_BALANCER_ARN --query 'Listeners[*].ListenerArn' --output text)

    # Loop through each listener ARN
    for listener in $listeners; do
        echo "Processing Listener ARN: $listener"

        # Step 3: List rules for each listener
        rules=$(aws elbv2 describe-rules --listener-arn $listener --query 'Rules[*].RuleArn' --output text)

        # Loop through each rule ARN
        for rule in $rules; do
            echo "Deleting Rule ARN: $rule"
            aws elbv2 delete-rule --rule-arn $rule
        done

        # Step 4: Delete listener after deleting its rules
        echo "Deleting Listener ARN: $listener"
        aws elbv2 delete-listener --listener-arn $listener
    done

    # Step 5: List and delete target groups for the current load balancer
    target_groups=$(aws elbv2 describe-target-groups --load-balancer-arn $LOAD_BALANCER_ARN --query 'TargetGroups[*].TargetGroupArn' --output text)

    for target_group in $target_groups; do
        echo "Processing Target Group ARN: $target_group"

        # Step 6: Deregister targets from the target group
        targets=$(aws elbv2 describe-target-health --target-group-arn $target_group --query 'TargetHealthDescriptions[*].Target.Id' --output text)
        
        for target in $targets; do
            echo "Deregistering Target ID: $target from Target Group ARN: $target_group"
            aws elbv2 deregister-targets --target-group-arn $target_group --targets Id=$target
        done

        # Step 7: Delete the target group
        echo "Deleting Target Group ARN: $target_group"
        aws elbv2 delete-target-group --target-group-arn $target_group
    done

    # Step 8: Delete the load balancer
    echo "Deleting Load Balancer ARN: $LOAD_BALANCER_ARN"
    aws elbv2 delete-load-balancer --load-balancer-arn $LOAD_BALANCER_ARN
done

echo "All load balancers and their associated resources have been deleted."
