resource "aws_launch_template" "launch_template" {
  name                   = "DemoLT"
  image_id               = "<ami>"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.secgrp.id]
  user_data              = base64encode(file("nginx.sh"))
}