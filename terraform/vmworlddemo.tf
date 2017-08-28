# Configure the OpenStack Provider
provider "openstack" {
  user_name   = "${var.user_name}"
  tenant_name = "${var.tenant_name}"
  password    = "${var.password}"
  auth_url    = "${var.auth_url}"
  insecure = true
}

# Initialize and generate Ansible files
resource "null_resource" "inventory_and_vars_setup" {
  # Prepare ansible variables
  provisioner "local-exec" {
    command = "cd ../ansible/${terraform.env}/group_vars && echo -e \"redis_master_ip : ${openstack_networking_floatingip_v2.floatip_vmwdemo_redis_master.fixed_ip}\\nredis_slave : false\\nredis_port : ${var.redis_port}\\nredis_password : ${var.redis_password}\\n\" > all.yml && cd ../../../terraform"
  }

  # Prepare ansible inventory
  provisioner "local-exec" {
    command = "cd ../ansible/${terraform.env} && echo -e \"[dbservers]\\nredis-master ip_address=${openstack_networking_floatingip_v2.floatip_vmwdemo_redis_master.fixed_ip} ansible_host=${openstack_networking_floatingip_v2.floatip_vmwdemo_redis_master.address} ansible_user=${var.ansible_user} ansible_ssh_private_key_file=~/.ssh/${var.key_pair} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'\\nredis-slave ip_address=${openstack_networking_floatingip_v2.floatip_vmwdemo_redis_slave.fixed_ip} ansible_host=${openstack_networking_floatingip_v2.floatip_vmwdemo_redis_slave.address} ansible_user=${var.ansible_user} ansible_ssh_private_key_file=~/.ssh/${var.key_pair} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'\\n\\n[webservers]\\nweb ip_address=${openstack_networking_floatingip_v2.floatip_vmwdemo_web.fixed_ip} ansible_host=${openstack_networking_floatingip_v2.floatip_vmwdemo_web.address} ansible_user=${var.ansible_user} ansible_ssh_private_key_file=~/.ssh/${var.key_pair} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'\" > hosts && cd ../../terraform"
  }
}
