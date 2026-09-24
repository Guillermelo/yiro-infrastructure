# Security Groups
resource "aws_security_group" "app" {
  name_prefix = "${var.name_prefix}-"
  description = "Application access from the ALB"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "from_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = var.alb_security_group_id

  description = "Application accepts traffic and health checks from the ALB."
  ip_protocol = "tcp"
  from_port   = var.app_port
  to_port     = var.app_port

  tags = var.tags
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = var.alb_security_group_id
  referenced_security_group_id = aws_security_group.app.id

  description = "ALB can send traffic to the application."
  ip_protocol = "tcp"
  from_port   = var.app_port
  to_port     = var.app_port

  tags = var.tags
}

# Launch Template
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  ami_id = coalesce(var.ami_id, data.aws_ami.amazon_linux_2023.id)
}

resource "aws_iam_role" "ec2" {
  name_prefix = "${var.name_prefix}-ec2-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

# SSM managed instance to not SSH into the instance
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name_prefix = "${var.name_prefix}-ec2-"
  role        = aws_iam_role.ec2.name
  tags        = var.tags
}

resource "aws_launch_template" "this" {
  name_prefix            = var.name_prefix
  image_id               = local.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.app.id]
  user_data              = var.user_data == null ? null : base64encode(var.user_data)

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2.arn
  }

  # block de bloque no de bloquear
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      encrypted   = true
      volume_type = "gp3"
      volume_size = var.root_volume_size
    }
  }

  # Instance Metadata Service
  # lets the instance know its information
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1 # depends on where im calling the IMDSv2 if in container set to 2
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(var.tags, {
      Name = "${var.name_prefix}-instance"
    })
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(var.tags, {
      Name = "${var.name_prefix}-volume"
    })
  }
}

resource "aws_autoscaling_group" "this" {
  name_prefix               = var.name_prefix
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  health_check_type         = var.health_check_type
  health_check_grace_period = 180

  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [var.target_group_arn]

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  # how to replace the instances when launch template changes
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50  # mantain at least 50% of the instances alive
      instance_warmup        = 180 # waits 180 seconds to to consider it healthy
    }
  }

  dynamic "tag" {
    for_each = merge(var.tags, {
      Name = "${var.name_prefix}-instance"
    })

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
