resource "aws_autoscaling_group" "asg" {
  name             = "DemoASG"
  max_size         = 10
  min_size         = 1
  desired_capacity = 2
  default_cooldown = 60

  launch_template {
    id = aws_launch_template.launch_template.id
  }

  vpc_zone_identifier = data.aws_subnet_ids.default_subnets.ids
  target_group_arns   = [aws_lb_target_group.target_group.arn]
  min_elb_capacity    = 1
  health_check_type   = "EC2"
}

resource "aws_autoscaling_policy" "asg-policy" {
  name                   = "DemoASG-policy"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "TargetTrackingScaling"
  enabled                = true

  target_tracking_configuration {
    target_value = "40.0"
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
  }
}