resource "aws_lb_target_group" "target_group" {
  name        = "DemoTG"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = "vpc-0cd9f1192089cc3d1"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    path                = "/index.html"
    port                = 80
    protocol            = "HTTP"
    unhealthy_threshold = 2
  }

  stickiness {
    enabled = false
    type    = "lb_cookie"
  }
}