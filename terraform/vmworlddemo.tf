variable "user_name" {}
variable "tenant_name" {}
variable "password" {}
variable "auth_url" {}
variable "external_gateway" {}
variable "subnet_cidr" {}
variable "image_id" {}
variable "flavor_id" {}
variable "key_pair" {}

# Configure the OpenStack Provider
provider "openstack" {
  user_name   = "${var.user_name}"
  tenant_name = "${var.tenant_name}"
  password    = "${var.password}"
  auth_url    = "${var.auth_url}"
  insecure = true
}

resource "openstack_networking_network_v2" "network_vmwdemo" {
  name = "network_vmwdemo"
  admin_state_up = "true"
}

resource "openstack_networking_router_v2" "router_vmwdemo" {
  region = "nova"
  name = "router_vmwdemo"
  external_gateway = "${var.external_gateway}"
}

resource "openstack_networking_subnet_v2" "subnet_vmwdemo" {
  name = "subnet_vmwdemo"
  network_id = "${openstack_networking_network_v2.network_vmwdemo.id}"
  cidr = "${var.subnet_cidr}"
  ip_version = 4
  enable_dhcp = true
  dns_nameservers = ["8.8.8.8"]
}


resource "openstack_networking_router_interface_v2" "router_interface_vmwdemo" {
  region = "nova"
  router_id = "${openstack_networking_router_v2.router_vmwdemo.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_vmwdemo.id}"
}

resource "openstack_compute_secgroup_v2" "secgroup_vmwdemo" {
  name = "secgroup_vmwdemo"
  description = "a security group"

  rule {
    from_port   = 22
    to_port     = 22
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

resource "openstack_networking_port_v2" "port_vmwdemo" {
  name = "port_vmwdemo"
  network_id = "${openstack_networking_network_v2.network_vmwdemo.id}"
  admin_state_up = "true"
  security_group_ids = ["${openstack_compute_secgroup_v2.secgroup_vmwdemo.id}"]

  fixed_ip {
      "subnet_id" =  "${openstack_networking_subnet_v2.subnet_vmwdemo.id}"
  }
}

resource "openstack_networking_floatingip_v2" "floatip_vmwdemo" {
  region = "nova"
  pool = "ext-net"
  port_id = "${openstack_networking_port_v2.port_vmwdemo.id}"
}


# Create a web server
resource "openstack_compute_instance_v2" "instance_vmwdemo" {
  name            = "instance_vmwdemo"
  image_id        = "${var.image_id}"
  flavor_id       = "${var.flavor_id}"
  key_pair        = "${var.key_pair}"

  network {
    port = "${openstack_networking_port_v2.port_vmwdemo.id}"
  }
}
