# fargate.tf
locals {
  app = "team3-app" # name prefix
}

resource "aws_security_group" "task_sg" {
  name        = "${local.app}-task-sg"
  description = "HTTP to the Fargate task"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "app" {
  name = "${local.app}-cluster"
}

# Decribes ECS: which image, how big, which port
resource "aws_ecs_task_definition" "app" {
  family                   = local.app
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512

  container_definitions = jsonencode([
    {
      name         = local.app
      image        = "ricardssmans/app:1.0" # first version; the pipeline deploys newer ones
      essential    = true
      portMappings = [{ containerPort = 80, protocol = "tcp" }]
    }
  ])
}

# Keeps 1 copy of the recipe running
resource "aws_ecs_service" "app" {
  name            = "${local.app}-service"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = ["subnet-0085786c1374a372c"]
    security_groups  = [aws_security_group.task_sg.id]
    assign_public_ip = true
  }

  # The CI/CD pipeline deploys new task definition revisions
  # Terraform must not revert them
  lifecycle {
    ignore_changes = [task_definition]
  }
}
