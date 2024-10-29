```bash
version: 0.2

phases:
  build:
    commands:
      - git clone https://github.com/davidawcloudsecurity/learn-aws-nuke.git
      - cd learn-aws-nuke
      - wget -c https://github.com/rebuy-de/aws-nuke/releases/download/v2.16.0/aws-nuke-v2.16.0-linux-amd64.tar.gz
      - tar -xvf aws-nuke-v2.16.0-linux-amd64.tar.gz
      - mv aws-nuke-v2.16.0-linux-amd64 aws-nuke
      - sudo mv aws-nuke /usr/local/bin/aws-nuke
      - REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
      - account_id=$(aws sts get-caller-identity --query Account --output text)
      - |
        {
        echo "regions:"
        echo "- $REGION"
        echo
        echo "resource-types:"
        echo "  excludes:"
        echo "  - CodeBuildProject"
        echo "  - ConfigServiceConfigRule
        echo "  - MachineLearningMLModel # Excluded due to ML being unavailable
        echo "  - MachineLearningDataSource # Excluded due to ML being unavailable
        echo "  - MachineLearningBranchPrediction # Excluded due to ML being unavailable
        echo "  - MachineLearningEvaluation # Excluded due to ML being unavailable
        echo "  - RoboMakerDeploymentJob # Deprecated Service
        echo "  - RoboMakerFleet # Deprecated Service
        echo "  - RoboMakerRobot # Deprecated Service
        echo "  - RoboMakerSimulationJob
        echo "  - RoboMakerRobotApplication
        echo "  - RoboMakerSimulationApplication
        echo "  - OpsWorksApp # Deprecated service
        echo "  - OpsWorksInstance # Deprecated service
        echo "  - OpsWorksLayer # Deprecated service
        echo "  - OpsWorksUserProfile # Deprecated service
        echo "  - OpsWorksCMBackup # Deprecated service
        echo "  - OpsWorksCMServer # Deprecated service
        echo "  - OpsWorksCMServerState # Deprecated service
        echo "  - CodeStarProject # Deprecated service
        echo "  - CodeStarConnection # Deprecated service
        echo "  - CodeStarNotification # Deprecated service
        echo "  - Cloud9Environment # Deprecated service
        echo "  - CloudSearchDomain # Deprecated service
        echo "  - RedshiftServerlessSnapshot # Deprecated service
        echo "  - RedshiftServerlessNamespace # Deprecated service
        echo "  - RedshiftServerlessWorkgroup # Deprecated service
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
      - cat config.yml
      - chmod 700 aws-nuke-target-all.sh
      - ./aws-nuke-target-all.sh
```
