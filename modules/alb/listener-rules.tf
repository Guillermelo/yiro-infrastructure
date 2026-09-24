resource "aws_lb_listener_rule" "backend" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  condition {
    path_pattern {
      values = ["/yiroappbk", "/yiroappbk/*"]
    }
  }

  transform {
    type = "url-rewrite"

    url_rewrite_config {
      rewrite {
        regex   = "^/yiroappbk/?(.*)$"
        replace = "/$1"
      }
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  tags = var.tags
}

resource "aws_lb_listener_rule" "sockets_alias" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 30

  condition {
    path_pattern {
      values = ["/socket/socket.io/*"]
    }
  }

  transform {
    type = "url-rewrite"

    url_rewrite_config {
      rewrite {
        regex   = "^/socket/(.*)$"
        replace = "/$1"
      }
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sockets.arn
  }

  tags = var.tags
}

resource "aws_lb_listener_rule" "sockets" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  condition {
    path_pattern {
      values = ["/socket.io/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sockets.arn
  }

  tags = var.tags
}
