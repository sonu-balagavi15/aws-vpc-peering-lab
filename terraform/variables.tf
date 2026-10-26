variable "aws_region" {
  description = "AWS Region for all resources"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_a_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "vpc_b_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "vpc_a_public_subnet_cidr" {
  type    = string
  default = "10.10.1.0/24"
}

variable "vpc_a_private_subnet_cidr" {
  type    = string
  default = "10.10.2.0/24"
}

variable "vpc_b_private_subnet_cidr" {
  type    = string
  default = "10.20.1.0/24"
}

variable "enable_ec2" {
  description = "Create the three EC2 instances. May incur charges; default is false."
  type        = bool
  default     = false
}

variable "instance_type" {
  description = "EC2 instance type when enable_ec2=true; verify eligibility and pricing."
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Existing EC2 key pair name in the selected region, required if EC2 is enabled."
  type        = string
  default     = ""
}

variable "admin_cidr" {
  description = "Your public IPv4 CIDR with /32, used for bastion SSH. Never use 0.0.0.0/0."
  type        = string
  default     = "127.0.0.1/32"
  validation {
    condition     = can(cidrhost(var.admin_cidr, 0)) && var.admin_cidr != "0.0.0.0/0"
    error_message = "admin_cidr must be a valid CIDR and must not be 0.0.0.0/0."
  }
}

variable "app_a_private_ip" {
  type    = string
  default = "10.10.2.10"
}

variable "app_b_private_ip" {
  type    = string
  default = "10.20.1.10"
}

variable "tags" {
  description = "Additional tags applied to resources."
  type        = map(string)
  default     = {
    Environment = "lab"
  }
}
