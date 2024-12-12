provider "aws" {
  region = "us-west-2"
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Create subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
}

# Create an internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# Create a security group
resource "aws_security_group" "ecs_sg" {
  name        = "ecs_security_group"
  description = "Allow inbound HTTP"
  vpc_id      = aws_vpc.main.id

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

# Create ALB (Application Load Balancer)
resource "aws_lb" "flask_lb" {
  name               = "flask-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.ecs_sg.id]
  subnets            = [aws_subnet.main.id]
}

# Create ALB Target Group
resource "aws_lb_target_group" "flask_target_group" {
  name     = "flask-api-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# Create ECS Cluster
resource "aws_ecs_cluster" "flask_cluster" {
  name = "flask-cluster"
}

# IAM Role for ECS Task
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# ECS Task Definition
resource "aws_ecs_task_definition" "flask_task" {
  family                   = "flask-api-task"
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  
  container_definitions = jsonencode([{
    name      = "flask-container"
    image     = "<aws_account_id>.dkr.ecr.us-west-2.amazonaws.com/my-flask-api:latest"
    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]
  }])
}

# ECS Service with Load Balancer
resource "aws_ecs_service" "flask_service" {
  name            = "flask-api-service"
  cluster         = aws_ecs_cluster.flask_cluster.id
  task_definition = aws_ecs_task_definition.flask_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  
  load_balancer {
    target_group_arn = aws_lb_target_group.flask_target_group.arn
    container_name   = "flask-container"
    container_port   = 80
  }

  network_configuration {
    subnets          = [aws_subnet.main.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
}

# # Output the ECS service URL (Load Balancer DNS)
# output "ecs_service_url" {
#   value = length(aws_ecs_service.flask_service.load_balancer) > 0 ? "http://${aws_ecs_service.flask_service.load_balancer[0].dns_name}" : "No Load Balancer Found"
# }
