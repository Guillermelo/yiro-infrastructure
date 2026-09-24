resource "aws_security_group" "alb" {
  name_prefix = "${var.name_prefix}-alb-"
  description = "ALB access from approved public CIDRs."
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  for_each = toset(var.allowed_ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTP from approved sources, including on-premise Traefik mirroring."
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80

  tags = var.tags
}

resource "aws_lb" "this" {
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb.id]
  subnets         = var.public_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_target_group" "backend" {
  port        = 5001
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    protocol = "HTTP"
    port     = "traffic-port"
    path     = var.backend_health_check_path
    matcher  = "200"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-backend"
  })
}

resource "aws_lb_target_group" "sockets" {
  port        = 5004
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    protocol = "HTTP"
    port     = "traffic-port"
    path     = var.sockets_health_check_path
    matcher  = "200"
  }

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-sockets"
  })
}
