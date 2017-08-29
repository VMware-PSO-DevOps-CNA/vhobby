#!/bin/sh

set -e -u -x

terraform_env=$1

echo "Preparing terraform and ansible files"
mkdir -p terraform/.terraform
echo $terraform_env > terraform/.terraform/environment
mkdir -p ansible/$terraform_env/group_vars

echo "Running terraform to update ansible hosts and variables for $terraform_env"
cd terraform
terraform env select $terraform_env
terraform taint null_resource.inventory_and_vars_setup
terraform apply

echo "Running ansible playbooks for $terraform_env"
cd ../ansible
ansible-playbook -i $terraform_env/hosts webservers.yml -e "env=$terraform_env"
ansible-playbook -i $terraform_env/hosts dbservers.yml --limit "redis-master" -e "env=$terraform_env"
ansible-playbook -i $terraform_env/hosts dbservers.yml --limit "redis-slave" -e "env=$terraform_env"
