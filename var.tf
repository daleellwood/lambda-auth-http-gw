
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "backend_lb_name" {
  description = "Name of the backend load balancer"
  type        = string
}

variable "private_subnet_names" {
  description = "List of private subnet names for VPC Link"
  type        = list(string)
}

variable "domain_name" {
  description = "Domain name for the backend service"
  type        = string
}

variable "allowed_ips" {
  description = "List of allowed IP addresses/CIDR blocks"
  type        = list(string)
  default     = []
}