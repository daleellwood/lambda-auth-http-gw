resource "aws_apigatewayv2_vpc_link" "api_vpclink" {
  name               = "api-vpclink"
  security_group_ids = [aws_security_group.api_vpclink.id]
  subnet_ids         = data.aws_subnets.private.ids
}


resource "aws_security_group" "api_vpclink" {
  name_prefix = "api-vpclink-"
  description = "Security group for the API Gateway VPC Link"

  vpc_id = data.aws_vpc.vpc.id

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_vpc_security_group_ingress_rule" "api_ingress" {
  security_group_id = aws_security_group.api_vpclink.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443
}


resource "aws_vpc_security_group_egress_rule" "api_egress" {
  security_group_id = aws_security_group.api_vpclink.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443
}