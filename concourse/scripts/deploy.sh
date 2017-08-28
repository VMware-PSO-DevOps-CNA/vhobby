#!/bin/sh

set -e -u -x

terraform_env=$1
terraform_state=$2
terraform_vars=$3

echo "Copying state and var files"
cd terraform
mkdir -p terraform.tfstate/$terraform_env
cp terraform_state terraform.tfstate/$terraform_env/terraform.tfstate

echo "Running terraform to update ansible hosts and variables for $terraform_env"
terraform env select $terraform_env
terraform taint null_resource.inventory_and_vars_setup
terraform apply

echo "Running ansible playbooks for $terraform_env"
cd ../ansible
ansible-playbook -i $terraform_env/hosts webservers.yml -e "env=$terraform_env"
ansible-playbook -i $terraform_env/hosts dbservers.yml --limit "redis-master" -e "env=$terraform_env"
ansible-playbook -i $terraform_env/hosts dbservers.yml --limit "redis-slave" -e "env=$terraform_env"
