############################################################
# GitHub Actions OIDC Provider
############################################################

# PURPOSE:
# Allows GitHub Actions to authenticate to AWS without storing long-lived AWS access keys in GitHub Secrets.

# FLOW:
# GitHub Actions
#       |
#       | OIDC token
#       v
# AWS IAM / STS
#       |
#       v
# GitHub Actions IAM Role


resource "aws_iam_openid_connect_provider" "github" {
  # GitHub's official OIDC identity provider.
  url = "https://token.actions.githubusercontent.com"

  # AWS STS is the intended audience of the GitHub token.
  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name}-github-oidc"
  })
}


############################################################
# ECS TASK EXECUTION ROLE
############################################################

# PURPOSE:
# This role is used by ECS/Fargate itself when starting and managing the container.

# Typical responsibilities:
# - Pull Docker images from ECR
# - Send container logs to CloudWatch
# - Retrieve secrets from Secrets Manager

# FLOW:
# ECS/Fargate
#      |
#      | assumes execution role
#      v
# ECR / CloudWatch / Secrets Manager
#

resource "aws_iam_role" "ecs_execution" {
  name = "${local.name}-ecs-execution-role"

  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}


############################################################
# Standard ECS Execution Permissions
############################################################
# AWS provides a managed policy containing the standard required by ECS task execution.

# This includes permissions commonly required to:
# - Pull container images from ECR
# - Send container logs to CloudWatch Logs
# Use the AWS-managed policy rather than recreating it


resource "aws_iam_role_policy_attachment" "ecs_execution_managed" {
  role = aws_iam_role.ecs_execution.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}



############################################################
# ECS Execution Role - Secrets Manager Access
############################################################

# PURPOSE:
# Allows ECS to retrieve the database secret when starting the container.
# This permission is intentionally restricted to the application's database secret only.

# Two secrets are used for PostgresDB Credentials :
# 1. Application DB secret
#    - DB_HOST
#    - DB_NAME
#    - DB_USER
#    - DB_PORT
#
# 2. RDS-managed secret
#    - password

resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name = "${local.name}-ecs-execution-secrets"

  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ReadDatabaseSecret"
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        # Least privilege: ECS can read only this application's DB secret.
        Resource = [
          # The provisioned application database configuration secret
          aws_secretsmanager_secret.postgresdb.arn,

          # RDS-managed master password secret
          aws_db_instance.postgresdb.master_user_secret[0].secret_arn
        ]      
      }
    ]
  })
}



############################################################
# GitHub 
############################################################



# GitHub Actions Deployment Role

# PURPOSE:
# This is the IAM role used by GitHub Actions to deploy the application to AWS.
# GitHub does NOT use permanent AWS access keys.
# Instead:
# GitHub Actions
#       |
#       | OIDC
#       v
# GitHub OIDC Provider
#       |
#       v
# GitHub Actions IAM Role
#       |
#       +------> ECR
#       |
#       +------> ECS
#
#

resource "aws_iam_role" "github_actions" {
  name = "${local.name}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "GitHubActionsOIDC"
        Effect = "Allow"

        # Only GitHub's configured OIDC provider can attempt to assume this role.
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }

        # GitHub uses web identity federation with AWS STS.
        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {

          # Make sure the GitHub token is intended for AWS STS.
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }

          # Only the configured GitHub repository and branch can assume this deployment role.
        
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:ref:refs/heads:${var.github_branch}"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}



# GitHub Actions Deployment Policy

# PURPOSE:
# Defines exactly what GitHub Actions is allowed to do after assuming the GitHub Actions IAM role.
resource "aws_iam_role_policy" "github_actions_deploy" {
  name = "${local.name}-github-actions-deploy"

  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [

      ######################################################
      # 1. ECR Authentication
      ######################################################
 
      # Allows GitHub Actions to obtain an ECR authorization token so Docker can authenticate with ECR.
      # AWS requires Resource = "*" for this operation.

      {
        Sid    = "ECRAuthentication"
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken"
        ]

        Resource = "*"
      },


      ######################################################
      # 2. ECR Image Push/Pull
      ######################################################

      # Allows GitHub Actions to push the frontend and backend Docker images into the project's ECR repositories.
      # The permissions are restricted to only these two repositories.

      {
        Sid    = "ECRPushPull"
        Effect = "Allow"

        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:InitiateLayerUpload",
          "ecr:ListImages",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]

        Resource = [
          aws_ecr_repository.frontend.arn,
          aws_ecr_repository.backend.arn
        ]
      },


      ######################################################
      # 3. ECS Task Definition
      ######################################################
      
      # A new ECS task definition revision is normally registered when a new Docker image is deployed.
      # GitHub Actions needs permission to register these new revisions.

      {
        Sid    = "ECSRegisterTaskDefinitions"
        Effect = "Allow"

        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition"
        ]

        # These ECS APIs require "*".
        Resource = "*"
      },


      ######################################################
      # 4. Update ECS Services
      ######################################################

      # This is what allows GitHub Actions to trigger a
      # deployment of the new task definition.
      # Only the project's frontend and backend services can be modified.
      

      {
        Sid    = "ECSDeployServices"
        Effect = "Allow"

        Action = [
          "ecs:DescribeServices",
          "ecs:UpdateService"
        ]

        Resource = [
          aws_ecs_service.frontend.arn,
          aws_ecs_service.backend.arn
        ]
      },


      ######################################################
      # 5. Pass ECS IAM Roles
      ######################################################
      #
      # When GitHub registers the ECS task definition, it references:
      # - ECS execution role
      # - ECS task role
      # AWS therefore requires GitHub to have iam:PassRole for those roles.
      # IMPORTANT : GitHub doesn't receive all permissions contained in these roles, put is only allowed to tell ECS to use these roles.

      {
        Sid    = "PassECSRoles"
        Effect = "Allow"

        Action = [
          "iam:PassRole"
        ]

        # Only these two ECS roles can be passed.
        Resource = [
          aws_iam_role.ecs_execution.arn
        ]

        # Additional security restriction : The roles can only be passed to ECS tasks.
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
  })
}