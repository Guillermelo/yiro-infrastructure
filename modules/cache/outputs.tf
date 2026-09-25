output "primary_endpoint_address" {
  description = "Primary Redis endpoint for writes and pub/sub."
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Reader Redis endpoint for read-only traffic."
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "port" {
  description = "Redis port."
  value       = aws_elasticache_replication_group.this.port
}

output "security_group_id" {
  description = "Security group ID assigned to Redis."
  value       = aws_security_group.cache.id
}
