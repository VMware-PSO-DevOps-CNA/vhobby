variable "user_name" {}
variable "tenant_name" {}
variable "password" {}
variable "auth_url" {}
variable "external_gateway" {}
variable "subnet_cidr" {}
variable "db_image_id" {}
variable "web_image_id" {}
variable "ansible_user" {}
variable "flavor_id" {}
variable "key_pair" {}
variable "redis_port" {}
variable "redis_password" {}

# Configure the OpenStack Provider
provider "openstack" {
  user_name   = "${var.user_name}"
  tenant_name = "${var.tenant_name}"
  password    = "${var.password}"
  auth_url    = "${var.auth_url}"
  insecure = true
}

resource "openstack_networking_network_v2" "network_vmwdemo" {
  name = "network_vmwdemo_${terraform.env}"
  admin_state_up = "true"
}

resource "openstack_networking_router_v2" "router_vmwdemo" {
  region = "nova"
  name = "router_vmwdemo_${terraform.env}"
  external_gateway = "${var.external_gateway}"
}

resource "openstack_networking_subnet_v2" "subnet_vmwdemo" {
  name = "subnet_vmwdemo_${terraform.env}"
  network_id = "${openstack_networking_network_v2.network_vmwdemo.id}"
  cidr = "${var.subnet_cidr}"
  ip_version = 4
  enable_dhcp = true
  dns_nameservers = ["10.132.71.1","8.8.8.8","8.8.4.4"]
}

resource "openstack_networking_router_interface_v2" "router_interface_vmwdemo" {
  region = "nova"
  router_id = "${openstack_networking_router_v2.router_vmwdemo.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_vmwdemo.id}"
}

resource "openstack_compute_secgroup_v2" "secgroup_vmwdemo" {
  name = "secgroup_vmwdemo_${terraform.env}"
  description = "a security group"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = "${terraform.env == "dev" ? 6300 : 6379}"
    to_port     = "${terraform.env == "dev" ? 6400 : 6379}"
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }
}

# Create redis master networking
resource "openstack_networking_port_v2" "port_vmwdemo_redis_master" {
  name = "port_vmwdemo_redis_master_${terraform.env}"
  network_id = "${openstack_networking_network_v2.network_vmwdemo.id}"
  admin_state_up = "true"
  security_group_ids = ["${openstack_compute_secgroup_v2.secgroup_vmwdemo.id}"]

  fixed_ip {
      "subnet_id" =  "${openstack_networking_subnet_v2.subnet_vmwdemo.id}"
  }
}

resource "openstack_networking_floatingip_v2" "floatip_vmwdemo_redis_master" {
  region = "nova"
  pool = "ext-net"
  port_id = "${openstack_networking_port_v2.port_vmwdemo_redis_master.id}"
}

# Create redis slave networking
resource "openstack_networking_port_v2" "port_vmwdemo_redis_slave" {
  name = "port_vmwdemo_redis_slave_${terraform.env}"
  network_id = "${openstack_networking_network_v2.network_vmwdemo.id}"
  admin_state_up = "true"
  security_group_ids = ["${openstack_compute_secgroup_v2.secgroup_vmwdemo.id}"]

  fixed_ip {
      "subnet_id" =  "${openstack_networking_subnet_v2.subnet_vmwdemo.id}"
  }
}

resource "openstack_networking_floatingip_v2" "floatip_vmwdemo_redis_slave" {
  region = "nova"
  pool = "ext-net"
  port_id = "${openstack_networking_port_v2.port_vmwdemo_redis_slave.id}"
}

# Create web server networking
resource "openstack_networking_port_v2" "port_vmwdemo_web" {
  name = "port_vmwdemo_web_${terraform.env}"
  network_id = "${openstack_networking_network_v2.network_vmwdemo.id}"
  admin_state_up = "true"
  security_group_ids = ["${openstack_compute_secgroup_v2.secgroup_vmwdemo.id}"]

  fixed_ip {
      "subnet_id" =  "${openstack_networking_subnet_v2.subnet_vmwdemo.id}"
  }
}

resource "openstack_networking_floatingip_v2" "floatip_vmwdemo_web" {
  region = "nova"
  pool = "ext-net"
  port_id = "${openstack_networking_port_v2.port_vmwdemo_web.id}"
}

resource "null_resource" "inventory_and_vars_setup" {
  # Prepare ansible variables
  provisioner "local-exec" {
    command = "cd ../ansible/${terraform.env}/group_vars && echo \"redis_master_ip : ${openstack_networking_floatingip_v2.floatip_vmwdemo_redis_master.fixed_ip}\\nredis_slave : false\\nredis_port : ${var.redis_port}\\nredis_password : ${var.redis_password}\\n\" > all.yml && cd ../../../terraform"
  }

  # Prepare ansible inventory
  provisioner "local-exec" {
    command = "cd ../ansible/${terraform.env} && echo \"[dbservers]\\nredis-master ip_address=${openstack_networking_floatingip_v2.floatip_vmwdemo_redis_master.fixed_ip} ansible_host=${openstack_networking_floatingip_v2.floatip_vmwdemo_redis_master.address} ansible_user=${var.ansible_user} ansible_ssh_private_key_file=~/.ssh/${var.key_pair} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'\\nredis-slave ip_address=${openstack_networking_floatingip_v2.floatip_vmwdemo_redis_slave.fixed_ip} ansible_host=${openstack_networking_floatingip_v2.floatip_vmwdemo_redis_slave.address} ansible_user=${var.ansible_user} ansible_ssh_private_key_file=~/.ssh/${var.key_pair} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'\\n\\n[webservers]\\nweb ip_address=${openstack_networking_floatingip_v2.floatip_vmwdemo_web.fixed_ip} ansible_host=${openstack_networking_floatingip_v2.floatip_vmwdemo_web.address} ansible_user=${var.ansible_user} ansible_ssh_private_key_file=~/.ssh/${var.key_pair} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'\" > hosts && cd ../../terraform"
  }
}

# Create a redis master server
resource "openstack_compute_instance_v2" "instance_vmwdemo_redis_master" {
  name = "instance_vmwdemo_redis_master_${terraform.env}"
  image_id = "${var.db_image_id}"
  flavor_id = "${var.flavor_id}"
  key_pair = "${var.key_pair}"
  depends_on = ["null_resource.inventory_and_vars_setup"]

  network {
    port = "${openstack_networking_port_v2.port_vmwdemo_redis_master.id}"
  }

  connection {
    user = "${var.ansible_user}"
    host = "${openstack_networking_floatingip_v2.floatip_vmwdemo_redis_master.address}"
    private_key = "${file("~/.ssh/${var.key_pair}")}"
    timeout = "10m"
  }

  # Trick to wait until ssh is ready to accept connections
  provisioner "remote-exec" {
    inline = ["ls"]
  }

  # Invoke Ansible playbook for Redis
  provisioner "local-exec" {
    command = "cd ../ansible && ansible-playbook -i ${terraform.env}/hosts dbservers.yml --limit \"redis-master\" -e \"env=${terraform.env}\" && cd ../terraform"
  }
}

# Create a redis slave server
resource "openstack_compute_instance_v2" "instance_vmwdemo_redis_slave" {
  name = "instance_vmwdemo_redis_slave_${terraform.env}"
  image_id = "${var.db_image_id}"
  flavor_id = "${var.flavor_id}"
  key_pair = "${var.key_pair}"
  depends_on = ["null_resource.inventory_and_vars_setup"]

  network {
    port = "${openstack_networking_port_v2.port_vmwdemo_redis_slave.id}"
  }

  connection {
    user = "${var.ansible_user}"
    host = "${openstack_networking_floatingip_v2.floatip_vmwdemo_redis_slave.address}"
    private_key = "${file("~/.ssh/${var.key_pair}")}"
    timeout = "10m"
  }

  # Trick to wait until ssh is ready to accept connections
  provisioner "remote-exec" {
    inline = ["ls"]
  }

  # Invoke Ansible playbook for Redis
  provisioner "local-exec" {
    command = "cd ../ansible && ansible-playbook -i ${terraform.env}/hosts dbservers.yml --limit \"redis-slave\" -e \"redis_slave=true env=${terraform.env}\" && cd ../terraform"
  }
}

# Create a web server
resource "openstack_compute_instance_v2" "instance_vmwdemo_web" {
  name = "instance_vmwdemo_web_${terraform.env}"
  image_id = "${var.web_image_id}"
  flavor_id = "${var.flavor_id}"
  key_pair = "${var.key_pair}"
  depends_on = ["null_resource.inventory_and_vars_setup"]

  network {
    port = "${openstack_networking_port_v2.port_vmwdemo_web.id}"
  }

  connection {
    user = "${var.ansible_user}"
    host = "${openstack_networking_floatingip_v2.floatip_vmwdemo_web.address}"
    private_key = "${file("~/.ssh/${var.key_pair}")}"
    timeout = "10m"
  }

  # Trick to wait until ssh is ready to accept connections
  provisioner "remote-exec" {
    inline = ["ls"]
  }

  provisioner "local-exec" {
    command = "cd ../ansible && ansible-playbook -i ${terraform.env}/hosts webservers.yml -e \"env=${terraform.env}\" && cd ../terraform"
  }
}

# Output floating ips for external connections
output "webserver_address" {
    value = "${openstack_networking_floatingip_v2.floatip_vmwdemo_web.address}"
}

output "redis_master_address" {
    value = "${openstack_networking_floatingip_v2.floatip_vmwdemo_redis_master.address}"
}

output "redis_slave_address" {
    value = "${openstack_networking_floatingip_v2.floatip_vmwdemo_redis_slave.address}"
}
