# Create web server networking
resource "openstack_networking_port_v2" "port_vmwdemo_web" {
  name = "port_vmwdemo_web_${terraform.env}"
  network_id = "${openstack_networking_network_v2.network_vmwdemo.id}"
  admin_state_up = "true"
  security_group_ids = ["${openstack_compute_secgroup_v2.secgroup_vmwdemo.id}"]

  fixed_ip {
      "subnet_id" =  "${openstack_networking_subnet_v2.subnet_vmwdemo.id}"
  }

  depends_on = ["openstack_networking_subnet_v2.subnet_vmwdemo"]
}

resource "openstack_networking_floatingip_v2" "floatip_vmwdemo_web" {
  region = "nova"
  pool = "ext-net"
  port_id = "${openstack_networking_port_v2.port_vmwdemo_web.id}"

  depends_on = ["openstack_networking_port_v2.port_vmwdemo_web"]
}

# Create a web server
resource "openstack_compute_instance_v2" "instance_vmwdemo_web" {
  name = "instance_vmwdemo_web_${terraform.env}"
  image_id = "${var.web_image_id}"
  flavor_id = "${var.flavor_id}"
  key_pair = "${var.key_pair}"
  depends_on = ["openstack_networking_floatingip_v2.floatip_vmwdemo_web", "null_resource.inventory_and_vars_setup"]

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
