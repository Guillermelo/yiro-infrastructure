resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
  })
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-igw"
    Environment = var.environment
  })
}

# Public subnets for ALB; RNAT does not require a subnet.
resource "aws_subnet" "public" {
  for_each = {
    for index, az in var.availability_zones : tostring(index) => az
  }
  vpc_id = aws_vpc.this.id
  # 10.0.0.0/24 and 10.0.1.0/24
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, tonumber(each.key)) # /24
  availability_zone       = each.value
  map_public_ip_on_launch = false # No automatic public IP
  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-public-${each.value}"
    Environment = var.environment
    Tier        = "public"
  })
}

resource "aws_subnet" "private_app" {
  for_each = {
    for index, az in var.availability_zones : tostring(index) => az
  }

  vpc_id            = aws_vpc.this.id
  availability_zone = each.value

  # 10.0.2.0/24 and 10.0.3.0/24
  cidr_block = cidrsubnet(
    var.vpc_cidr, 4,
    tonumber(each.key) + length(var.availability_zones)
  )

  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-app-${each.value}"
    Environment = var.environment
    Tier        = "application"
  })
}

resource "aws_subnet" "private_data" {
  for_each = {
    for index, az in var.availability_zones : tostring(index) => az
  }

  vpc_id            = aws_vpc.this.id
  availability_zone = each.value

  # 10.0.4.0/24 and 10.0.5.0/24
  cidr_block = cidrsubnet(var.vpc_cidr, 4,
    tonumber(each.key) + (2 * length(var.availability_zones))
  )

  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-data-${each.value}"
    Environment = var.environment
    Tier        = "data"
  })
}


# Automatic RNAT: AWS manages IPs and AZ coverage.
resource "aws_nat_gateway" "this" {
  vpc_id            = aws_vpc.this.id
  availability_mode = "regional"
  connectivity_type = "public"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-rnat"
    Environment = var.environment
  })

  depends_on = [aws_internet_gateway.this]
}

# Public internet access.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-public-rt"
    Environment = var.environment
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Both AZs share the regional NAT route.
resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.this.id
  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-app-rt"
    Environment = var.environment
  })
}

resource "aws_route" "private_app_internet" {
  route_table_id         = aws_route_table.private_app.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

resource "aws_route_table_association" "private_app" {
  for_each = aws_subnet.private_app

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_app.id
}

# Data subnets: local VPC route only.
resource "aws_route_table" "private_data" {
  vpc_id = aws_vpc.this.id
  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-data-rt"
    Environment = var.environment
  })
}

resource "aws_route_table_association" "private_data" {
  for_each = aws_subnet.private_data

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_data.id
}
