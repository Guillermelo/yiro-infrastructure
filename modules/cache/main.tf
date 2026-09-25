# Subnets where elasticache is allowed to allcate nodes
resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name_prefix}-subnets"
  subnet_ids = var.subnet_ids

  tags = var.tags
}

resource "aws_security_group" "cache" {
  name_prefix = "${var.name_prefix}-"
  description = "Redis access from approved application security groups"

  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_app" {
  for_each = var.allowed_security_group_ids

  security_group_id            = aws_security_group.cache.id
  referenced_security_group_id = each.value

  description = "Redis access from an application security group."
  ip_protocol = "tcp"
  from_port   = 6379
  to_port     = 6379

  tags = var.tags
}

# Primary end Replicas are handled here
resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "${var.name_prefix}-redis"
  description          = "Redis replication group for backend and sockets"

  engine         = "redis"
  engine_version = var.engine_version
  node_type      = var.node_type
  port           = 6379

  num_cache_clusters         = 2 # this maybe shoud be a variable to change it
  automatic_failover_enabled = true
  multi_az_enabled           = true

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.cache.id]

  transit_encryption_enabled = true # tls
  at_rest_encryption_enabled = true # encrypted storage
  auto_minor_version_upgrade = true

  snapshot_retention_limit = var.snapshot_retention_limit # how much time retains snapshots

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-redis"
  })


}
