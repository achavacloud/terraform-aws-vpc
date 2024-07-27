output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the VPC"
}

output "public_subnet_ids" {
  value       = aws_subnet.public_subnet[*].id
  description = "IDs of the public subnets"
}

output "private_subnet_ids" {
  value       = aws_subnet.private_subnet[*].id
  description = "IDs of the private subnets"
}

output "public_sg_id" {
  value       = aws_security_group.public_sg.id
  description = "ID of the public security group"
}

output "private_sg_id" {
  value       = aws_security_group.private_sg.id
  description = "ID of the private security group"
}

output "public_nacl_id" {
  value       = aws_network_acl.public_nacl.id
  description = "ID of the public network ACL"
}

output "private_nacl_id" {
  value       = aws_network_acl.private_nacl.id
  description = "ID of the private network ACL"
}
