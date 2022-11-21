resource "aws_lb" "alb" {
  name                             = "DemoALB"
  internal                         = false
  load_balancer_type               = "application"
  security_groups                  = [aws_security_group.secgrp.id]
  subnets                          = data.aws_subnet_ids.default_subnets.ids
  enable_cross_zone_load_balancing = true
  ip_address_type                  = "ipv4"
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}