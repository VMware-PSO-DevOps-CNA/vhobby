resource "openstack_networking_network_v2" "network_vmwdemo" {
  name = "network_vmwdemo_${terraform.env}"
  admin_state_up = "true"
  depends_on = ["openstack_networking_router_v2.router_vmwdemo"]
}

resource "openstack_networking_subnet_v2" "subnet_vmwdemo" {
  name = "subnet_vmwdemo_${terraform.env}"
  network_id = "${openstack_networking_network_v2.network_vmwdemo.id}"
  cidr = "${var.subnet_cidr}"
  ip_version = 4
  enable_dhcp = true
  dns_nameservers = ["10.20.20.1", "10.132.71.1","8.8.8.8","8.8.4.4"]
  depends_on = ["openstack_networking_network_v2.network_vmwdemo"]
}
