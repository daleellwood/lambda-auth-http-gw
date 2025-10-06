# VPC Data Source
data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Private Subnets for VPC Link
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
  filter {
    name   = "tag:Name"
    values = var.private_subnet_names
  }
}

# Backend Load Balancer
data "aws_lb" "backend" {
  name = var.backend_lb_name
}

# Backend Load Balancer Listener
data "aws_lb_listener" "backend_443" {
  load_balancer_arn = data.aws_lb.backend.arn
  port              = 443
}

# Bastion Instances for Dynamic IP Collection
data "aws_instances" "bastions" {
  filter {
    name   = "tag:Name"
    values = ["*${var.bastion}*"]
  }
}

data "aws_instance" "bastion_instances" {
  count       = length(data.aws_instances.bastions.ids)
  instance_id = data.aws_instances.bastions.ids[count.index]
}

locals {
  bastion_ips = [for instance in data.aws_instance.bastion_instances : instance.public_ip]
  
  combined_ip_whitelist = concat(
    var.ip_whitelist,
    local.bastion_ips
  )
}