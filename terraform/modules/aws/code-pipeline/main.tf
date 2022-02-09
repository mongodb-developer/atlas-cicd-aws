variable "PrivateRegistryCredentials" {
    default = {
        username = "piepet"
        password = "2ca26fb7-3d9b-4f68-b891-8ee0d023eaf6"
    }
    type = map(string)
}
resource "aws_secretsmanager_secret" "PrivateRegistryCredentials" {
  name = "PrivateRegistryCredentials"
}
resource "aws_secretsmanager_secret_version" "PrivateRegistryCredentials" {
  secret_id     = aws_secretsmanager_secret.PrivateRegistryCredentials.id
  secret_string = jsonencode(var.PrivateRegistryCredentials)
}
resource "aws_ssm_parameter" "org_id" {
  name  = join("-",[var.project_name,"org-id",var.region,"base"])
  type  = "SecureString"
  value = var.org_id
}
resource "aws_ssm_parameter" "org_api_public_key" {
  name  = join("-",[var.project_name,"org-public-api-key",var.region,"base"])
  type  = "SecureString"
  value = var.org_api_pub_key
}

resource "aws_ssm_parameter" "org_api_private_key" {
  name  = join("-",[var.project_name,"org-private-api-key",var.region,"base"])
  type  = "SecureString"
  value = var.org_api_pri_key 
}

resource "aws_s3_bucket" "cache" {
  bucket = join("-",[var.project_name,var.environment_name,"pipeline-cache"]) 
  force_destroy = true
}
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = join("-",[var.project_name,var.environment_name,"artifactstore"])
  force_destroy = true
}
resource "aws_s3_bucket_public_access_block" "cache" {
  bucket = aws_s3_bucket.cache.id
  block_public_acls   = true
  block_public_policy = true
}  
resource "aws_s3_bucket_public_access_block" "codepipeline" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  block_public_acls   = true
  block_public_policy = true
}  
resource "aws_codecommit_repository" "base-repo" {
  repository_name = join("-",[var.project_name,"base-repo"]) 
}
resource "aws_sns_topic" "base-codecommit" {
  name = join("-",[var.project_name,"codecommit-base-topic"])
}
resource "aws_codecommit_trigger" "base-trigger" {
  repository_name = aws_codecommit_repository.base-repo.repository_name

  trigger {
    name            = "all"
    events          = ["all"]
    destination_arn = aws_sns_topic.base-codecommit.arn
  }
}

resource "aws_kms_key" "a" {
  description             = "KMS key 1"
  deletion_window_in_days = 10
}
resource "aws_kms_alias" "a" {
  name_prefix = join("",["alias/",var.project_name,"/",var.environment_name,"/",var.region,"/key-alias/"])
  target_key_id = aws_kms_key.a.key_id
}


resource "aws_codebuild_project" "deploy_dev" {
  name          = join("-",["mongodb-atlas-dev",var.project_name,var.environment_name, var.region]) 
  description   = join("-",["mongodb-atlas-dev",var.project_name,var.environment_name,var.region,"project"]) 
  build_timeout = "25"
  service_role  = aws_iam_role.codebuildServiceRole.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.cache.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "piepet/cicd-mongodb:46"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    registry_credential {
      credential = aws_secretsmanager_secret.PrivateRegistryCredentials.id
      credential_provider = "SECRETS_MANAGER"
    }

    environment_variable {
      name  = "private_api_key"
      value = join("-",[var.project_name,"private-api-key",var.region,"dev"])
      type  = "PARAMETER_STORE"
    }    
    environment_variable {
      name  = "org_id"
      value = join("-",[var.project_name,"org-id",var.region,"base"])
      type  = "PARAMETER_STORE"
    }        
    environment_variable {
      name  = "project_id"
      value = join("-",[var.project_name,"project-id",var.region,"dev"])
      type  = "PARAMETER_STORE"
    }    
    
    environment_variable {
      name  = "public_api_key"
      value = join("-",[var.project_name,"public-api-key",var.region,"dev"])
      type  = "PARAMETER_STORE"
    }    
    environment_variable {
      name  = "db_username"
      value = join("-",[var.project_name,"dbusername",var.region,"dev"])
      type  = "PARAMETER_STORE"
    }        

  }

  logs_config {
    cloudwatch_logs {
      group_name  = "${var.project_name}-dev-${var.region}-log-group"
      stream_name = "${var.project_name}-dev-${var.region}-log-stream"
    }

  }

  source {
    type            = "CODECOMMIT"
    location        = join("",["https://git-codecommit.${var.region}.amazonaws.com/v1/repos/", aws_codecommit_repository.base-repo.repository_name ]) 
    git_clone_depth = 1
    git_submodules_config {
      fetch_submodules = true
    }
    buildspec = yamlencode({
      version = "0.2"
      phases = {
        build = {
          commands = [
            "cd terraform", 
            "./deploy_env.sh ${var.region} $org_id $public_api_key $private_api_key $db_username ${var.project_name} dev apply"
          ]
        }
      }
    })
  }

  source_version = var.master_branch

  tags = {
    Environment = var.environment_name
  }
  
  
}

resource "aws_codebuild_project" "deploy_test" {
  name          = join("-",["mongodb-atlas-test",var.project_name,var.environment_name, var.region]) 
  description   = join("-",["mongodb-atlas-test",var.project_name,var.environment_name,var.region,"project"]) 
  build_timeout = "25"
  service_role  = aws_iam_role.codebuildServiceRole.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.cache.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "piepet/cicd-mongodb:46"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    registry_credential {
      credential = aws_secretsmanager_secret.PrivateRegistryCredentials.id
      credential_provider = "SECRETS_MANAGER"
    }

    environment_variable {
      name  = "private_api_key"
      value = join("-",[var.project_name,"private-api-key",var.region,"test"])
      type  = "PARAMETER_STORE"
    }    
    environment_variable {
      name  = "org_id"
      value = join("-",[var.project_name,"org-id",var.region,"base"])
      type  = "PARAMETER_STORE"
    }        
    environment_variable {
      name  = "project_id"
      value = join("-",[var.project_name,"project-id",var.region,"test"])
      type  = "PARAMETER_STORE"
    }    
    
    environment_variable {
      name  = "public_api_key"
      value = join("-",[var.project_name,"public-api-key",var.region,"test"])
      type  = "PARAMETER_STORE"
    }    
    environment_variable {
      name  = "db_username"
      value = join("-",[var.project_name,"dbusername",var.region,"test"])
      type  = "PARAMETER_STORE"
    }        

  }

  logs_config {
    cloudwatch_logs {
      group_name  = "${var.project_name}-test-${var.region}-log-group"
      stream_name = "${var.project_name}-test-${var.region}-log-stream"
    }

  }

  source {
    type            = "CODECOMMIT"
    location        = join("",["https://git-codecommit.${var.region}.amazonaws.com/v1/repos/", aws_codecommit_repository.base-repo.repository_name ]) 
    git_clone_depth = 1
    git_submodules_config {
      fetch_submodules = true
    }
    buildspec = yamlencode({
      version = "0.2"
      phases = {
        build = {
          commands = [
            "cd terraform", 
           "./deploy_env.sh ${var.region} $org_id $public_api_key $private_api_key $db_username ${var.project_name} test apply"
          ]
        }
      }
    })
  }

  source_version = var.master_branch

  tags = {
    Environment = var.environment_name
  }
  
  
}

resource "aws_codebuild_project" "deploy_prod" {
  name          = join("-",["mongodb-atlas-prod",var.project_name,var.environment_name, var.region]) 
  description   = join("-",["mongodb-atlas-prod",var.project_name,var.environment_name,var.region,"project"]) 
  build_timeout = "25"
  service_role  = aws_iam_role.codebuildServiceRole.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.cache.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "piepet/cicd-mongodb:46"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    registry_credential {
      credential = aws_secretsmanager_secret.PrivateRegistryCredentials.id
      credential_provider = "SECRETS_MANAGER"
    }

    environment_variable {
      name  = "private_api_key"
      value = join("-",[var.project_name,"private-api-key",var.region,"prod"])
      type  = "PARAMETER_STORE"
    }    
    environment_variable {
      name  = "org_id"
      value = join("-",[var.project_name,"org-id",var.region,"base"])
      type  = "PARAMETER_STORE"
    }        
    environment_variable {
      name  = "project_id"
      value = join("-",[var.project_name,"project-id",var.region,"prod"])
      type  = "PARAMETER_STORE"
    }    
    
    environment_variable {
      name  = "public_api_key"
      value = join("-",[var.project_name,"public-api-key",var.region,"prod"])
      type  = "PARAMETER_STORE"
    }    

    environment_variable {
      name  = "db_username"
      value = join("-",[var.project_name,"dbusername",var.region,"prod"])
      type  = "PARAMETER_STORE"
    }        
    

  }

  logs_config {
    cloudwatch_logs {
      group_name  = "${var.project_name}-prod-${var.region}-log-group"
      stream_name = "${var.project_name}-prod-${var.region}-log-stream"
    }

  }

  source {
    type            = "CODECOMMIT"
    location        = join("",["https://git-codecommit.${var.region}.amazonaws.com/v1/repos/", aws_codecommit_repository.base-repo.repository_name ]) 
    git_clone_depth = 1
    git_submodules_config {
      fetch_submodules = true
    }
    buildspec = yamlencode({
      version = "0.2"
      phases = {
        build = {
          commands = [
            "cd terraform", 
            "./deploy_env.sh ${var.region} $org_id $public_api_key $private_api_key $db_username ${var.project_name} prod apply"
          ]
        }
      }
    })
  }

  source_version = var.master_branch

  tags = {
    Environment = var.environment_name
  }
  
  
}



resource "aws_codebuild_project" "deploy_base" {
  name          = join("-",["mongodb-atlas-base",var.project_name,"base", var.region]) 
  description   = join("-",["mongodb-atlas-base",var.project_name,"base",var.region,"project"]) 
  build_timeout = "25"
  service_role  = aws_iam_role.codebuildServiceRole.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.cache.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "piepet/cicd-mongodb:46"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    registry_credential {
      credential = aws_secretsmanager_secret.PrivateRegistryCredentials.id
      credential_provider = "SECRETS_MANAGER"
    }


    environment_variable {
      name  = "org_api_pri_key"
      value = join("-",[var.project_name,"org-private-api-key",var.region,"base"])
      type  = "PARAMETER_STORE"
    }    
    environment_variable {
      name  = "org_id"
      value = join("-",[var.project_name,"org-id",var.region,"base"])
      type  = "PARAMETER_STORE"
    }    
    
    environment_variable {
      name  = "org_api_pub_key"
      value = join("-",[var.project_name,"org-public-api-key",var.region,"base"])
      type  = "PARAMETER_STORE"
    }    


  }

  logs_config {
    cloudwatch_logs {
      group_name  = "${var.project_name}-base-${var.region}-log-group"
      stream_name = "${var.project_name}-base-${var.region}-log-stream"
    }

  }

  source {
    type            = "CODECOMMIT"
    location        = join("",["https://git-codecommit.${var.region}.amazonaws.com/v1/repos/", aws_codecommit_repository.base-repo.repository_name]) 
    git_clone_depth = 1
    git_submodules_config {
      fetch_submodules = true
    }
    buildspec = yamlencode({
      version = "0.2"
      phases = {
        build = {
          commands = [
            "cd terraform", 
            "./deploy_baseline.sh ${var.region} $org_id $org_api_pub_key $org_api_pri_key nouser ${var.project_name} base apply"            
          ]
        }
      }
    })
  }

  source_version = var.master_branch

  tags = {
    Environment = var.environment_name
  }
  
  
}

resource "aws_codebuild_project" "teardown_all" {
  name          = join("-",["mongodb-atlas-teardown",var.project_name,var.environment_name, var.region]) 
  description   = join("-",["mongodb-atlas-teardown",var.project_name,var.environment_name,var.region,"project"]) 
  build_timeout = "25"
  service_role  = aws_iam_role.codebuildServiceRole.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.cache.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "piepet/cicd-mongodb:46"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    registry_credential {
      credential = aws_secretsmanager_secret.PrivateRegistryCredentials.id
      credential_provider = "SECRETS_MANAGER"
    }

    environment_variable {
      name  = "org_api_pri_key"
      value = join("-",[var.project_name,"org-private-api-key",var.region,"base"])
      type  = "PARAMETER_STORE"
    }    
    environment_variable {
      name  = "org_id"
      value = join("-",[var.project_name,"org-id",var.region,"base"])
      type  = "PARAMETER_STORE"
    }    
    
    environment_variable {
      name  = "org_api_pub_key"
      value = join("-",[var.project_name,"org-public-api-key",var.region,"base"])
      type  = "PARAMETER_STORE"
    }    


  }

  logs_config {
    cloudwatch_logs {
      group_name  = "${var.project_name}-base-${var.environment_name}-${var.region}-log-group"
      stream_name = "${var.project_name}-base-${var.environment_name}-${var.region}-log-stream"
    }

  }

  source {
    type            = "CODECOMMIT"
    location        = join("",["https://git-codecommit.${var.region}.amazonaws.com/v1/repos/", aws_codecommit_repository.base-repo.repository_name]) 
    git_clone_depth = 1
    git_submodules_config {
      fetch_submodules = true
    }
    buildspec = yamlencode({
      version = "0.2"
      phases = {
        build = {
          commands = [
             "cd terraform",
             "./deploy_env.sh ${var.region} $org_id $org_api_pub_key $org_api_pri_key no_user ${var.project_name} prod destroy",
             "./deploy_env.sh ${var.region} $org_id $org_api_pub_key $org_api_pri_key no_user ${var.project_name} test destroy",
             "./deploy_env.sh ${var.region} $org_id $org_api_pub_key $org_api_pri_key no_user ${var.project_name} dev destroy"
          ]
        }
      }
    })
  }

  source_version = var.master_branch

  tags = {
    Environment = var.environment_name
  }
  
  
}

resource "aws_codepipeline" "codepipeline" {
  name  = "mongodb-atlas-${var.project_name}-${var.environment_name}-${var.region}-codepipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["MyApp"]
      configuration = {        
        BranchName       = "master"
        RepositoryName   = aws_codecommit_repository.base-repo.repository_name
      }
    }
  }

  stage {
    name = "deploy-Base"
    action {
      name             = "Deploy"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["MyApp"]
      version          = "1"
      configuration = {
        EnvironmentVariables = "[{\"name\":\"environment_name\",\"value\":\"dev\",\"type\":\"PLAINTEXT\"}]"
        ProjectName = aws_codebuild_project.deploy_base.name
      }
    }
  }

  stage {
    name = "deploy-Dev"
    action {
      name             = "Deploy"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["MyApp"]
      version          = "1"
      configuration = {
        EnvironmentVariables = "[{\"name\":\"environment_name\",\"value\":\"dev\",\"type\":\"PLAINTEXT\"}]"
        ProjectName = aws_codebuild_project.deploy_dev.name
      }
    }
  }

  stage {
    name = "deploy-Test"
    action {
      name             = "Deploy"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["MyApp"]
      version          = "1"
      configuration = {
        EnvironmentVariables = "[{\"name\":\"environment_name\",\"value\":\"test\",\"type\":\"PLAINTEXT\"}]"
        ProjectName = aws_codebuild_project.deploy_test.name
      }
    }
  }
  stage {
    name = "deploy-Prod"
    action {
      name             = "Deploy"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["MyApp"]
      version          = "1"
      configuration = {
        EnvironmentVariables = "[{\"name\":\"environment_name\",\"value\":\"prod\",\"type\":\"PLAINTEXT\"}]"
        ProjectName = aws_codebuild_project.deploy_prod.name
      }
    }
  }
  stage {
    name = "Gate"
    action {
      name             = "Approval"
      category         = "Approval"
      owner            = "AWS"
      provider         = "Manual"
      version          = "1"
      configuration = {
        NotificationArn = aws_sns_topic.base-codecommit.arn
        CustomData = "Do you approve the plan?"
      }      
    }
  }
  stage {
    name = "teardown"
    action {
      name             = "Deploy"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["MyApp"]
      version          = "1"
      configuration = {
        EnvironmentVariables = "[{\"name\":\"environment_name\",\"value\":\"prod\",\"type\":\"PLAINTEXT\"}]"
        ProjectName = aws_codebuild_project.teardown_all.name
      }
    }
  }  
}

resource "aws_iam_role" "codepipeline_role" {
  name = join("-",["mongodb-atlas",var.project_name,var.environment_name,var.region,"codepipeline-role"])

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }   
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = join("-",["mongodb-atlas",var.project_name,var.environment_name,var.region, "codepipeline-policy"])
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
{
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Condition": {
                "StringEqualsIfExists": {
                    "iam:PassedToService": [
                        "cloudformation.amazonaws.com",
                        "elasticbeanstalk.amazonaws.com",
                        "ec2.amazonaws.com",
                        "ecs-tasks.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Action": [
                "codecommit:CancelUploadArchive",
                "codecommit:GetBranch",
                "codecommit:GetCommit",
                "codecommit:GetRepository",
                "codecommit:GetUploadArchiveStatus",
                "codecommit:UploadArchive"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codedeploy:CreateDeployment",
                "codedeploy:GetApplication",
                "codedeploy:GetApplicationRevision",
                "codedeploy:GetDeployment",
                "codedeploy:GetDeploymentConfig",
                "codedeploy:RegisterApplicationRevision"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codestar-connections:UseConnection"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "elasticbeanstalk:*",
                "ec2:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "cloudwatch:*",
                "s3:*",
                "sns:*",
                "cloudformation:*",
                "rds:*",
                "sqs:*",
                "ecs:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "lambda:InvokeFunction",
                "lambda:ListFunctions"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "opsworks:CreateDeployment",
                "opsworks:DescribeApps",
                "opsworks:DescribeCommands",
                "opsworks:DescribeDeployments",
                "opsworks:DescribeInstances",
                "opsworks:DescribeStacks",
                "opsworks:UpdateApp",
                "opsworks:UpdateStack"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "cloudformation:CreateStack",
                "cloudformation:DeleteStack",
                "cloudformation:DescribeStacks",
                "cloudformation:UpdateStack",
                "cloudformation:CreateChangeSet",
                "cloudformation:DeleteChangeSet",
                "cloudformation:DescribeChangeSet",
                "cloudformation:ExecuteChangeSet",
                "cloudformation:SetStackPolicy",
                "cloudformation:ValidateTemplate"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild",
                "codebuild:BatchGetBuildBatches",
                "codebuild:StartBuildBatch"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Effect": "Allow",
            "Action": [
                "devicefarm:ListProjects",
                "devicefarm:ListDevicePools",
                "devicefarm:GetRun",
                "devicefarm:GetUpload",
                "devicefarm:CreateUpload",
                "devicefarm:ScheduleRun"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "servicecatalog:ListProvisioningArtifacts",
                "servicecatalog:CreateProvisioningArtifact",
                "servicecatalog:DescribeProvisioningArtifact",
                "servicecatalog:DeleteProvisioningArtifact",
                "servicecatalog:UpdateProduct"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:ValidateTemplate"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:DescribeImages"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "states:DescribeExecution",
                "states:DescribeStateMachine",
                "states:StartExecution"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "appconfig:StartDeployment",
                "appconfig:StopDeployment",
                "appconfig:GetDeployment"
            ],
            "Resource": "*"
        }
  ]
}
EOF
}


resource "aws_iam_role" "codebuildServiceRole" {
  name = "mongodb-atlas-${var.project_name}-${var.environment_name}-${var.region}-codebuild-service-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "codeBuildPolicy" {
  name =  "mongodb-atlas-codebuild-${var.environment_name}-${var.region}-policy"
  role = aws_iam_role.codebuildServiceRole.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
   {
            "Effect": "Allow",
            "Action": [
                "ssm:*"
            ],
            "Resource": "*"
    },
    {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
    },
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject"
      ],
      "Resource": "*"
    },
{
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
                "codecommit:GitPull"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
                "s3:PutObject",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codebuild:CreateReportGroup",
                "codebuild:CreateReport",
                "codebuild:UpdateReport",
                "codebuild:BatchPutTestCases",
                "codebuild:BatchPutCodeCoverages",
                "secretsmanager:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::mongo-atlas-templates",
                "arn:aws:s3:::mongo-atlas-templates/*"
            ],
            "Action": [
                "s3:PutObject",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
              "cloudwatch:*",
              "logs:*",
              "ssm:*",
              "secretsmanager:*",
              "s3:*",
              "kms:*"
            ],
            "Resource": "*"
        },            
        {
          "Effect": "Allow",
          "Action": [        
            "codecommit:*",
            "sns:*",
            "codebuild:*",
            "codepipeline:*",
            "iam:*",
            "ec2:*"
          ],
          "Resource": "*"
        }
      ]
}
EOF
}

