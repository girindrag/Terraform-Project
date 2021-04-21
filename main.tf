# Define required providers
terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.35.0"
    }
  }
}
# Configure the OpenStack Provider
provider "openstack" {
  user_name   = "girindra"
  tenant_name = "girindra-dev"
  password    = "sonukumar@123"
  auth_url    = "https://cloud.tcpro.cz:30500/v3/"
  region      = "RegionOne"
}



# Security Groups and Rules
resource "openstack_networking_secgroup_v2" "my_secgroup" {
  name        = "my_secgroup"
  description = "Allow all"
}

resource "openstack_networking_secgroup_rule_v2" "rule1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2.my_secgroup.id
}
# Network and Subnet
resource "openstack_networking_network_v2" "client_net" {
  name           = "client_net"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "client_subnet" {
  name       = "client_subnet"
  network_id = openstack_networking_network_v2.client_net.id
  cidr       = "172.1.1.0/24"
}


# keypair:
resource "openstack_compute_keypair_v2" "mykey1" {
  name = "mykey2"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDnOBz/T/UOvsJhW6pHC5MWdIRS3APU6lgQ6uFD3dMrbZyI9gWq3WxkNaqWfr+AxyNR27i2TRKB+o10PtLcXHQUxaVVVvRiFlo09rzeAXaXNjXbbZYUiHz7Jj2aicCHAfxFLFtvFovxQ8ZQm18WH21bFUEy6Vqq8XV7usltQhoXaquhrdRXAiU63XacSXdsldVb/0qplHHE89TZeMN6V78OCQD0uJL8dml6wP4uaPaBud2Rk7KU+CnO6daJIKXjO205B02lGcVyM1odmbpNZYqhGYjEGyn8EMUtJ4nChLyBLCIu3h+x+MEA5lZR/fdbeZ8nCbOMZ2SynqJVdkToAwdJ iamgirindra@gmail.com"
}
# Router
resource "openstack_networking_router_v2" "myrouter" {
  name             = "myrouter"
  external_gateway = var.public_pool_id
}

resource "openstack_networking_router_interface_v2" "client_net_itf" {
  router_id = openstack_networking_router_v2.myrouter.id
  subnet_id = openstack_networking_subnet_v2.client_subnet.id
}
# Floating IP
resource "openstack_networking_floatingip_v2" "fip_1" {
  pool = "public"
}


resource "openstack_compute_floatingip_associate_v2" "fip_1" {
  floating_ip = openstack_networking_floatingip_v2.fip_1.address
  instance_id = openstack_compute_instance_v2.vm1.id
}
# Instance
resource "openstack_compute_instance_v2" "vm1" {
  name            = "vm1"
  image_id        = var.myimage
  flavor_id       = var.myflavor
  key_pair        = "${openstack_compute_keypair_v2.mykey1.name}"
  security_groups = ["${openstack_networking_secgroup_v2.my_secgroup.id}"]
  network {
    uuid = openstack_networking_network_v2.client_net.id
  }
}
