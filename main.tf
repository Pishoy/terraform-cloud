terraform {
  required_providers {
    flexibleengine = {
      source  = "FlexibleEngineCloud/flexibleengine"
      #version = "1.17.0"
    }
  }
  #required_version = ">= 0.13"
}

# 1. Configure the FlexibleEngine Provider
provider "flexibleengine" {
  access_key  = var.access_key
  secret_key  = var.secret_key
  domain_name = var.domain_name
  tenant_name = "eu-west-0"
  auth_url    = "https://iam.eu-west-0.prod-cloud-ocb.orange-business.com/v3"
  region      = "eu-west-0"
}


# 2. create VPC
resource "flexibleengine_vpc_v1" "vpc_prod" {
  name = "production_VPC_test22"
  cidr = "10.0.0.0/16"

}

# 3. create 2 subnets (10.0.3.0/24 and 10.0.4.0/24) in "production_VPC_test22" 
resource "flexibleengine_vpc_subnet_v1" "subnet_1" {
  name = var.subnet_prefix[0].name
  cidr = var.subnet_prefix[0].cidr
  gateway_ip = "10.0.3.1"
  vpc_id = flexibleengine_vpc_v1.vpc_prod.id
}

resource "flexibleengine_vpc_subnet_v1" "subnet_22" {
  name = var.subnet_prefix[1].name
  cidr = var.subnet_prefix[1].cidr
  gateway_ip = "10.0.4.1"
  vpc_id = flexibleengine_vpc_v1.vpc_prod.id
}


# 4.security Group
resource "flexibleengine_networking_secgroup_v2" "secgroup_1" {
  name        = "secgroup_1"
  description = "My neutron security group"
}

resource "flexibleengine_networking_secgroup_rule_v2" "allow22" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = flexibleengine_networking_secgroup_v2.secgroup_1.id
}


resource "flexibleengine_networking_secgroup_rule_v2" "allow443" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = flexibleengine_networking_secgroup_v2.secgroup_1.id
}



resource "flexibleengine_networking_secgroup_rule_v2" "allow80" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = flexibleengine_networking_secgroup_v2.secgroup_1.id
}

resource "flexibleengine_networking_secgroup_rule_v2" "allowoutbound" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "any"
  port_range_min    = 0
  port_range_max    = 0
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = flexibleengine_networking_secgroup_v2.secgroup_1.id
}


# 5.create VM
resource "flexibleengine_compute_instance_v2" "ecs" {
  name            = "production_ecs_bishoy"
  image_id        = "830c9d19-4dea-4017-bb7e-c61a0846421f"
  flavor_name       = "s6.small.1"
  key_pair        = "bishoykey"
  security_groups = [flexibleengine_networking_secgroup_v2.secgroup_1.id]
  auto_recovery   = true
  count = 1
  tags = {name = terraform.workspace}

  network {
    uuid = flexibleengine_vpc_subnet_v1.subnet_22.id
  }
 
  provisioner "local-exec" {
    command = "echo ${self.name} >> /tmp/private_ips.txt"
  }


}

