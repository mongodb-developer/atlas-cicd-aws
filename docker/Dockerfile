FROM ubuntu:18.04

MAINTAINER Pierre Petersson <pierre@thinkworks.se>

# Install required gnupg package
RUN apt-get update && apt-get -y install gnupg

RUN apt-get update && \
    apt-get -qy full-upgrade && \
    apt-get install -qy curl && \
    apt-get install -qy curl && \
    curl -sSL https://get.docker.com/ | sh

# Install required ca-certificates to prevent the error in the certificate verification
RUN apt-get -y install ca-certificates && update-ca-certificates

# Import the public key used by the package management system
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4

# Create a list file for MongoDB
RUN echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.0.list

# Reload local package database
RUN apt-get update

# Install the MongoDB packages
RUN apt-get -y install mongodb-org-shell
RUN apt-get -y install mongodb-org-tools


RUN \
# Update
apt-get update -y && \
# Install Unzip
apt-get install unzip -y && \
# need wget
apt-get install wget -y && \
# vim
apt-get install vim -y


################################
# Install Terraform
################################

# Download terraform for linux
#RUN wget https://releases.hashicorp.com/terraform/0.11.11/terraform_0.11.11_linux_amd64.zip
RUN wget https://releases.hashicorp.com/terraform/0.14.9/terraform_0.14.9_linux_amd64.zip
# Unzip
RUN unzip terraform_0.14.9_linux_amd64.zip

# Move to local bin
RUN mv terraform /usr/local/bin/
# Check that it's installed
RUN terraform --version 

################################
# Install python
################################

RUN apt-get install -y python3-pip
#RUN ln -s /usr/bin/python3 python
RUN pip3 install --upgrade pip
RUN python3 -V
RUN pip --version

################################
# Install AWS CLI
################################
RUN pip install awscli --upgrade --user
RUN apt-get install curl -y
RUN apt-get install jq -y
RUN apt-get install git -y
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install -i /usr/local/aws-cli -b /usr/local/bin

# needed for aws codecommit credentialhelper
RUN apt-get install groff -y

RUN apt-get install libcap2-bin -y
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    rm -rf /var/lib/apt/lists/*

RUN apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
RUN apt-get update && apt-get install vault -y
RUN setcap cap_ipc_lock= /usr/bin/vault


ARG TG_VERSION=latest
RUN set -eux \
	&& git clone https://github.com/gruntwork-io/terragrunt /terragrunt \
	&& cd /terragrunt \
	&& if [ "${TG_VERSION}" = "latest" ]; then \
		VERSION="$( git describe --abbrev=0 --tags )"; \
	else \
		VERSION="$( git tag | grep -E "v${TG_VERSION}\.[.0-9]+" | sort -Vu | tail -1 )" ;\
	fi \
	&& curl -sS -L \
		https://github.com/gruntwork-io/terragrunt/releases/download/${VERSION}/terragrunt_linux_amd64 \
		-o /usr/bin/terragrunt \
	&& chmod +x /usr/bin/terragrunt

# Test binaries
RUN set -eux \
	&& terragrunt --version


# add aws cli location to path
#ENV PATH=~/.local/bin:$PATH

# Adds local templates directory and contents in /usr/local/terrafrom-templates
#ADD templates /usr/local/bin/templates
RUN rm terraform_0.14.9_linux_amd64.zip
RUN mkdir ~/.aws && touch ~/.aws/credentials
