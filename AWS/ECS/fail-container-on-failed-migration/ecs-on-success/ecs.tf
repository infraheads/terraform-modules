resource "aws_ecs_cluster" "cluster" {
  name = "ecs_cluster"
}

resource "aws_ecs_cluster_capacity_providers" "capacity_provider" {
  capacity_providers = [ "FARGATE" ]
  cluster_name = aws_ecs_cluster.cluster.name
}

resource "aws_ecs_task_definition" "task_def" {
  family = "success"
  container_definitions = <<TASK_DEFINITION
[
  {
    "image": "hakobmkoyan771/ifconfig:success",
    "memory": 2048,
    "name": "success",
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80,
        "protocol": "tcp"
      }
    ]
  }
]
TASK_DEFINITION
  
  cpu = 1024
  memory = 2048
  network_mode = "awsvpc"
  requires_compatibilities = [ "FARGATE" ]
}

resource "aws_ecs_service" "success" {
  name = "success-svc"
  cluster = aws_ecs_cluster.cluster.arn
  desired_count = 1
  launch_type = "FARGATE"
  network_configuration {
    assign_public_ip = true
    subnets = [ "subnet-03f20810e9a9bcf9f", "subnet-041a52133419bb94a" ]
  }
  task_definition = aws_ecs_task_definition.task_def.family
  wait_for_steady_state = true
}
