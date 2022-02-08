#!/bin/bash
# example command
# ./deploy_env.sh eu-west-1 60363d82783fd71b1e508cd5 iruhenwv 4b01113b-c9f1-430d-89c9-4b6cbfa1ed4d demon bygghazz33  dev apply
region=$1
orgId=$2
orgPubKey=$3
orgPrivKey=$4
dbUsername=$5
projectName=$6
environment=$7
mode=$8
s3="s3bckt-atlas-${projectName}-${environment}"
# Begin script in case all parameters are correct
echo "-----------------------------------"
echo "Input parameters"
echo "-----------------------------------"
echo "BUCKETNAME: ${s3}"
echo "REGION: ${region}"
echo "ORG_ID: ${orgId}"
echo "ORG_PUB: ${orgPubKey}"
echo "ProjectName: ${projectName}"
echo "ENVIRONMENT NAME: ${environment}"
echo "mode: ${mode}"
export TF_INPUT="false"
export TF_VAR_region="$region"
export TF_VAR_bucket="$s3"
export TF_VAR_key="tf-atlas-project-${projectName}-${environment}"
if aws s3 ls "s3://${s3}" 2>&1 | grep -q 'NoSuchBucket'
then    
    aws s3api create-bucket --bucket $s3 --region $region --create-bucket-configuration LocationConstraint=$region --no-cli-pager
else
  echo "Bucket already exists, will try to use bucket for terraform state"
fi
sleep 10
echo "Bootstrapping MongoDB Atlas and creating Atlas Cluster for ${projectName}-${environment}"
cd environment/${environment}/
terraform init -reconfigure \
    -backend-config="bucket=${s3}" \
    -backend-config="region=${region}" \
    -backend-config="key=tf-atlas-project-${projectName}-${environment}"
## Ensure api key is removed from state file, to ensure it will not be availble. Only from statefile
terraform $mode -var="org_api_pri_key=${orgPrivKey}" -var="org_api_pub_key=${orgPubKey}" -var="org_id=${orgId}" -var="environment_name=${environment}"  -var="db_username=${dbUsername}" -var="project_name=${projectName}" -var="region=${region}" -auto-approve