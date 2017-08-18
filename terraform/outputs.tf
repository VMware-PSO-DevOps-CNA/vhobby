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
