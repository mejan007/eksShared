output "instance_id" {
  description = "The ID of the EC2 instance."
  value       = aws_instance.ec2_instance.id
}

output "instance_arn" {
  description = "The ARN of the EC2 instance."
  value       = aws_instance.ec2_instance.arn
}

output "private_ip" {
  description = "The private IP address of the instance."
  value       = aws_instance.ec2_instance.private_ip
}

output "public_ip" {
  description = "The public IP address of the instance (if applicable)."
  value       = aws_instance.ec2_instance.public_ip
}

output "created_security_group_id" {
  description = "The ID of the security group created by this module (if any)."
  value       = var.create_security_group ? aws_security_group.ec2_sg[0].id : null
}