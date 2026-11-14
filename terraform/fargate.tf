# fargate-minimal.tf
# Bare minimum: one ECS cluster + one Fargate service running a public Docker Hub image.
# No load balancer, no log group, no execution role (a public Docker Hub image needs none).

variable "app_name" {
  description = "Name prefix. Use your team name so it does not clash with other teams."
  type        = string
  default     = "team3-app"
}

variable "app_image" {
  description = "Docker Hub image for our app."
  type        = string
  default     = "ricardssmans/app:1.0"
}

# Default network of the account
data "aws_vpc" "app_vpc" {
  default = true
}

data "aws_subnets" "app_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.app_vpc.id]
  }
}

# Firewall: web traffic straight to the container
resource "aws_security_group" "task_sg" {
  name        = "${var.app_name}-task-sg"
  description = "HTTP to the Fargate task"
  vpc_id      = data.aws_vpc.app_vpc.id

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

# 1. The cluster
resource "aws_ecs_cluster" "app" {
  name = "${var.app_name}-cluster"
}

# 2. The recipe: which image, how big, which port
resource "aws_ecs_task_definition" "app" {
  family                   = var.app_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512

  container_definitions = jsonencode([
    {
      name         = var.app_name
      image        = var.app_image
      essential    = true
      portMappings = [{ containerPort = 80, protocol = "tcp" }]
    }
  ])
}

# 3. The service: keeps 1 copy of the recipe running
resource "aws_ecs_service" "app" {
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = ["subnet-0085786c1374a372c"]
    security_groups  = [aws_security_group.task_sg.id]
    assign_public_ip = true # needed to pull the image and to reach the app
  }
}

output "cluster_name" {
  value = aws_ecs_cluster.app.name
}

output "service_name" {
  value = aws_ecs_service.app.name
}
