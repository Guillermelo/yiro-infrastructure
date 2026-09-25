output "security_group_id" {
  description = "Application instance security group ID"
  value       = aws_security_group.app.id
}
