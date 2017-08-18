resource "openstack_networking_router_v2" "router_vmwdemo" {
  region = "nova"
  name = "router_vmwdemo_${terraform.env}"
  external_gateway = "${var.external_gateway}"
}

resource "openstack_networking_router_interface_v2" "router_interface_vmwdemo" {
  region = "nova"
  router_id = "${openstack_networking_router_v2.router_vmwdemo.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_vmwdemo.id}"
}
