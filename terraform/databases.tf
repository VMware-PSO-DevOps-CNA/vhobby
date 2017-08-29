# Create redis master networking
resource "openstack_networking_port_v2" "port_vmwdemo_redis_master" {
  name = "port_vmwdemo_redis_master_${terraform.env}"
  network_id = "${openstack_networking_network_v2.network_vmwdemo.id}"
  admin_state_up = "true"
  security_group_ids = ["${openstack_compute_secgroup_v2.secgroup_vmwdemo.id}"]

  fixed_ip {
      "subnet_id" =  "${openstack_networking_subnet_v2.subnet_vmwdemo.id}"
  }

  depends_on = ["openstack_networking_subnet_v2.subnet_vmwdemo"]
}

resource "openstack_networking_floatingip_v2" "floatip_vmwdemo_redis_master" {
  region = "nova"
  pool = "ext-net"
  port_id = "${openstack_networking_port_v2.port_vmwdemo_redis_master.id}"

  depends_on = ["openstack_networking_port_v2.port_vmwdemo_redis_master"]
}

# Create a redis master server
resource "openstack_compute_instance_v2" "instance_vmwdemo_redis_master" {
  name = "instance_vmwdemo_redis_master_${terraform.env}"
  image_id = "${var.db_image_id}"
  flavor_id = "${var.flavor_id}"
  key_pair = "${var.key_pair}"
  depends_on = ["openstack_networking_floatingip_v2.floatip_vmwdemo_redis_master", "null_resource.inventory_and_vars_setup"]

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

# Create redis slave networking
resource "openstack_networking_port_v2" "port_vmwdemo_redis_slave" {
  name = "port_vmwdemo_redis_slave_${terraform.env}"
  network_id = "${openstack_networking_network_v2.network_vmwdemo.id}"
  admin_state_up = "true"
  security_group_ids = ["${openstack_compute_secgroup_v2.secgroup_vmwdemo.id}"]

  fixed_ip {
      "subnet_id" =  "${openstack_networking_subnet_v2.subnet_vmwdemo.id}"
  }

  depends_on = ["openstack_networking_subnet_v2.subnet_vmwdemo"]
}

resource "openstack_networking_floatingip_v2" "floatip_vmwdemo_redis_slave" {
  region = "nova"
  pool = "ext-net"
  port_id = "${openstack_networking_port_v2.port_vmwdemo_redis_slave.id}"

  depends_on = ["openstack_networking_port_v2.port_vmwdemo_redis_slave"]
}

# Create a redis slave server
resource "openstack_compute_instance_v2" "instance_vmwdemo_redis_slave" {
  name = "instance_vmwdemo_redis_slave_${terraform.env}"
  image_id = "${var.db_image_id}"
  flavor_id = "${var.flavor_id}"
  key_pair = "${var.key_pair}"
  depends_on = ["openstack_networking_floatingip_v2.floatip_vmwdemo_redis_slave", "null_resource.inventory_and_vars_setup"]

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
