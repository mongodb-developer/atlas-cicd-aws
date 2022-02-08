# Building a scalable and secure continous delivery pipeline for MongoDB Atlas with Terraform

## Prerequsites
 You need to have an Atlas account and an Organisation. You will also need an AWS accounts. The AWS account will be hosting the AWS Codepipeline to orchestrate the provisiong of MongoDB Atlas. 

### Set your environment variables

```
# You'll find this in your Atlas console as described in prerequisites
export ATLAS_ORG_ID=60363d827822271b1e508cd5

# The public part of the Atlas Org key you created previously 
export ATLAS_ORG_PUBLIC_KEY=34qreoms

# The private part of the Atlas Org key you created previously 
export ATLAS_ORG_PRIVATE_KEY=4a041131-c2f1-430d-89c9-4b6cbfa1ed4d

# Pick a username, the script will create this database user in Atlas
export DB_USER_NAME=demouser

# Pick a project base name, the script will appended -dev, -test, -prod depending on environment
export ATLAS_PROJECT_NAME=blogcicd6

# The AWS region you want to deploy into
export AWS_DEFAULT_REGION=eu-west-1

# The AWS public programmatic access key
export AWS_ACCESS_KEY_ID=AKIAZFC33SWZUN4WWMC

# The AWS private programmatic access key
export AWS_SECRET_ACCESS_KEY=nmarrFFFIska1231wx9DmNdzIgThBA1t5fEfw4uJA
```

## Bootstrap Atlas and AWS accounts
To create the CI/CD pipeline and Atlas resorces do the following steps.

1. Clone repository, and cd to root of the folder
2. Start docker container, invoke below command in root of git repository,
```
docker container run -it --rm -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION -e ATLAS_ORG_ID -e ATLAS_ORG_PUBLIC_KEY -e ATLAS_ORG_PRIVATE_KEY -e DB_USER_NAME -e ATLAS_PROJECT_NAME -v ${PWD}/terraform:/terraform piepet/cicd-mongodb:46
```

3. Bootstrap AWS account, create vpc, pipeline 
```
cd terraform 
./deploy_baseline.sh $AWS_DEFAULT_REGION $ATLAS_ORG_ID $ATLAS_ORG_PUBLIC_KEY $ATLAS_ORG_PRIVATE_KEY $DB_USER_NAME $ATLAS_PROJECT_NAME base apply
```
4. Clone the repository that was created in AWS CodeCommit and push the terraform folder. If you just want to get the terraform dir pushed to get started and see the clusters spin up you can run this script to force-push an initial version. You should now be able to see that the pipeline has been triggered in the AWS CodePipeline console.
```
./git_push_terraform.sh
```
You will need to create Git Credentials in AWS IAM to be able to modify the repo from outside the container, see AWS documentation https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-gc.html

Link to AWS Codepipline: https://eu-west-1.console.aws.amazon.com/codesuite/codepipeline/start?region=eu-west-1

# You can also manually provision enviroments
        ./deploy_env.sh <region> <atlasOrgid> <atlasOrgPublicAPIKey> <atlasOrgPrivateAPIKey> <dbUserName> <projectName> <environmentName> <createMode>
        
        example:
        cd terraform
        ./deploy_baseline.sh eu-west-1 60363d82AAfd71b1e508cd5 irxxeawv 4b01113b-ddf1-4a01-89c9-4b6cbfa1ed4d demon blogcicd6 dev apply
