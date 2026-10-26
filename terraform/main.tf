terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  common_tags = merge(var.tags, {
    Project     = "AWS VPC Peering Lab"
    ManagedBy   = "Terraform"
  })
}

resource "aws_vpc" "a" {
  cidr_block           = var.vpc_a_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(local.common_tags, { Name = "ewb-vpc-a" })
}

resource "aws_vpc" "b" {
  cidr_block           = var.vpc_b_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(local.common_tags, { Name = "ewb-vpc-b" })
}

resource "aws_subnet" "a_public" {
  vpc_id                  = aws_vpc.a.id
  cidr_block              = var.vpc_a_public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = merge(local.common_tags, { Name = "ewb-a-public" })
}

resource "aws_subnet" "a_private" {
  vpc_id                  = aws_vpc.a.id
  cidr_block              = var.vpc_a_private_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false
  tags = merge(local.common_tags, { Name = "ewb-a-private" })
}

resource "aws_subnet" "b_private" {
  vpc_id                  = aws_vpc.b.id
  cidr_block              = var.vpc_b_private_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false
  tags = merge(local.common_tags, { Name = "ewb-b-private" })
}

resource "aws_internet_gateway" "a" {
  vpc_id = aws_vpc.a.id
  tags = merge(local.common_tags, { Name = "ewb-igw-a" })
}

resource "aws_vpc_peering_connection" "a_b" {
  vpc_id      = aws_vpc.a.id
  peer_vpc_id = aws_vpc.b.id
  auto_accept = true
  tags = merge(local.common_tags, { Name = "ewb-a-b-peer" })
}

resource "aws_route_table" "a_public" {
  vpc_id = aws_vpc.a.id
  tags = merge(local.common_tags, { Name = "ewb-rt-a-public" })
}

resource "aws_route" "a_public_default" {
  route_table_id         = aws_route_table.a_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.a.id
}

resource "aws_route" "a_public_to_b" {
  route_table_id            = aws_route_table.a_public.id
  destination_cidr_block    = var.vpc_b_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.a_b.id
}

resource "aws_route_table_association" "a_public" {
  subnet_id      = aws_subnet.a_public.id
  route_table_id = aws_route_table.a_public.id
}

resource "aws_route_table" "a_private" {
  vpc_id = aws_vpc.a.id
  tags = merge(local.common_tags, { Name = "ewb-rt-a-private" })
}

resource "aws_route" "a_private_to_b" {
  route_table_id            = aws_route_table.a_private.id
  destination_cidr_block    = var.vpc_b_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.a_b.id
}

resource "aws_route_table_association" "a_private" {
  subnet_id      = aws_subnet.a_private.id
  route_table_id = aws_route_table.a_private.id
}

resource "aws_route_table" "b_private" {
  vpc_id = aws_vpc.b.id
  tags = merge(local.common_tags, { Name = "ewb-rt-b-private" })
}

resource "aws_route" "b_private_to_a" {
  route_table_id            = aws_route_table.b_private.id
  destination_cidr_block    = var.vpc_a_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.a_b.id
}

resource "aws_route_table_association" "b_private" {
  subnet_id      = aws_subnet.b_private.id
  route_table_id = aws_route_table.b_private.id
}

resource "aws_security_group" "bastion" {
  name        = "ewb-sg-bastion"
  description = "SSH only from the configured administrator CIDR"
  vpc_id      = aws_vpc.a.id
  tags = merge(local.common_tags, { Name = "ewb-sg-bastion" })

  ingress {
    description = "Administrator SSH; configure admin_cidr before enabling EC2"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app_a" {
  name        = "ewb-sg-app-a"
  description = "Private App-A; SSH from bastion and ICMP from App-B"
  vpc_id      = aws_vpc.a.id
  tags = merge(local.common_tags, { Name = "ewb-sg-app-a" })

  ingress {
    description     = "SSH from bastion security group"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    description = "ICMP echo from App-B private IP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["${var.app_b_private_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app_b" {
  name        = "ewb-sg-app-b"
  description = "Private App-B; SSH from bastion and ICMP from App-A"
  vpc_id      = aws_vpc.b.id
  tags = merge(local.common_tags, { Name = "ewb-sg-app-b" })

  ingress {
    description     = "SSH from bastion security group across VPC peering"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    description = "ICMP echo from App-A private IP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["${var.app_a_private_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "bastion" {
  count                       = var.enable_ec2 ? 1 : 0
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.a_public.id
  private_ip                  = "10.10.1.10"
  associate_public_ip_address  = true
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  tags = merge(local.common_tags, { Name = "ewb-bastion" })
}

resource "aws_instance" "app_a" {
  count                       = var.enable_ec2 ? 1 : 0
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.a_private.id
  private_ip                  = var.app_a_private_ip
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.app_a.id]
  tags = merge(local.common_tags, { Name = "ewb-app-a" })
}

resource "aws_instance" "app_b" {
  count                       = var.enable_ec2 ? 1 : 0
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.b_private.id
  private_ip                  = var.app_b_private_ip
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.app_b.id]
  tags = merge(local.common_tags, { Name = "ewb-app-b" })
}
