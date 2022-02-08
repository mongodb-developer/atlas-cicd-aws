echo "project: ${ATLAS_PROJECT_NAME} region: ${AWS_DEFAULT_REGION}"
git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true
cd ..
git clone https://git-codecommit.${AWS_DEFAULT_REGION}.amazonaws.com/v1/repos/${ATLAS_PROJECT_NAME}-base-repo
cp -R terraform/ ${ATLAS_PROJECT_NAME}-base-repo/
cd ${ATLAS_PROJECT_NAME}-base-repo
git add terraform/
git config --global user.email "me@example.com"
git commit -m 'initial terraform template'
git push
echo "git repo created at $PWD and pushed to https://git-codecommit.${AWS_DEFAULT_REGION}.amazonaws.com/v1/repos/${ATLAS_PROJECT_NAME}-base-repo "