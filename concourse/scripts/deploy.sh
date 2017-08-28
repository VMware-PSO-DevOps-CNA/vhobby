#!/bin/sh

set -e -u -x

terraform_env=$1

echo "Copying state and var files"
mkdir -p terraform/terraform.tfstate/$terraform_env
cp ../terraform_state_test/terraform.tfstate terraform/terraform.tfstate/$terraform_env/terraform.tfstate
cp ../terraform_vars_test/terraform.tfvars terraform/terraform.tfvars

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
