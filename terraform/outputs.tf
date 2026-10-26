output "vpc_a_id" {
  description = "ID of VPC A"
  value       = aws_vpc.a.id
}

output "vpc_b_id" {
  description = "ID of VPC B"
  value       = aws_vpc.b.id
}

output "vpc_peering_connection_id" {
  description = "VPC peering connection ID"
  value       = aws_vpc_peering_connection.a_b.id
}

output "subnet_ids" {
  description = "Subnet IDs by subnet name"
  value = {
    vpc_a_public  = aws_subnet.a_public.id
    vpc_a_private = aws_subnet.a_private.id
    vpc_b_private = aws_subnet.b_private.id
  }
}

output "bastion_public_ip" {
  description = "Bastion public IPv4 address (null when EC2 is disabled)"
  value       = var.enable_ec2 ? aws_instance.bastion[0].public_ip : null
}

output "app_a_private_ip" {
  description = "App-A private IPv4 address (null when EC2 is disabled)"
  value       = var.enable_ec2 ? aws_instance.app_a[0].private_ip : null
}

output "app_b_private_ip" {
  description = "App-B private IPv4 address (null when EC2 is disabled)"
  value       = var.enable_ec2 ? aws_instance.app_b[0].private_ip : null
}
