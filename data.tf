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