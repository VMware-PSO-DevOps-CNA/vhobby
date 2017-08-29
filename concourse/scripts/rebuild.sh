#!/bin/sh

set -e -u -x

terraform_env=$1

echo "Preparing terraform and ansible files"
mkdir -p terraform/.terraform
echo $terraform_env > terraform/.terraform/environment
mkdir -p terraform/terraform.tfstate.d/$terraform_env
cp ../terraform_state/terraform.tfstate terraform/terraform.tfstate.d/$terraform_env/terraform.tfstate
cp ../terraform_vars/terraform.tfvars terraform/terraform.tfvars
mkdir -p ansible/$terraform_env/group_vars

echo "Running terraform to rebuild $terraform_env"
cd terraform
terraform env select $terraform_env
# Dont think wildcard is working for taint yet and dont want to run destroy
terraform taint openstack_networking_network_v2.network_vmwdemo
terraform taint openstack_compute_secgroup_v2.secgroup_vmwdemo
terraform taint openstack_networking_router_v2.router_vmwdemo
terraform taint openstack_networking_subnet_v2.subnet_vmwdemo
terraform taint openstack_networking_router_interface_v2.router_interface_vmwdemo
terraform taint openstack_networking_port_v2.port_vmwdemo_web
terraform taint openstack_networking_port_v2.port_vmwdemo_redis_master
terraform taint openstack_networking_port_v2.port_vmwdemo_redis_slave
terraform taint openstack_networking_floatingip_v2.floatip_vmwdemo_redis_master
terraform taint openstack_networking_floatingip_v2.floatip_vmwdemo_web
terraform taint openstack_networking_floatingip_v2.floatip_vmwdemo_redis_slave
terraform taint null_resource.inventory_and_vars_setup
terraform taint openstack_compute_instance_v2.instance_vmwdemo_redis_slave
terraform taint openstack_compute_instance_v2.instance_vmwdemo_redis_master
terraform taint openstack_compute_instance_v2.instance_vmwdemo_web
terraform apply
