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
    from_port   = "${terraform.env == "test" ? 6300 : 6379}"
    to_port     = "${terraform.env == "test" ? 6400 : 6379}"
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

  depends_on = ["openstack_networking_subnet_v2.subnet_vmwdemo"]
}
