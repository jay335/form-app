# --- IAM Role for ECS Task Execution
# This role is required by Fargate to run tasks and access resources like ECR and CloudWatch.
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role-form-app"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}
# --- Policy to allow pulling from Public ECR
resource "aws_iam_role_policy" "ecs_public_ecr_pull" {
  name = "ecs-public-ecr-pull-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr-public:GetAuthorizationToken",
          "ecr-public:BatchCheckLayerAvailability",
          "ecr-public:840"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = "sts:GetServiceBearerToken",
        Resource = "*",
        Condition = {
          StringEquals = {
            "sts:AWSServiceName" = "ecr-public.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Attach the policy that allows ECS tasks to pull from ECR and write logs
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- ECS Cluster
resource "aws_ecs_cluster" "app_cluster" {
  name = "form-app-cluster"
}

# --- ECS Task Definitions
# Frontend Task Definition
resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "form-app-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "frontend-container"
      image     = "public.ecr.aws/${var.ecr_registry_alias}/form-app-frontend:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/form-app-frontend"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# Backend Task Definition
resource "aws_ecs_task_definition" "backend_task" {
  family                   = "form-app-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend-container"
      image     = "public.ecr.aws/${var.ecr_registry_alias}/form-app-backend:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/form-app-backend"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}


# --- ECS Services (to manage and deploy tasks)
# Frontend Service
resource "aws_ecs_service" "frontend_service" {
  name            = "form-app-frontend-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.frontend_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.frontend_sg.id]
    subnets         = [aws_subnet.private[0].id]
  }

  depends_on = [
    # Assuming your listener is defined elsewhere
    aws_lb_listener.frontend_listener
  ]

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_tg.arn
    container_name   = "frontend-container"
    container_port   = 3000
  }
}

# Backend Service
resource "aws_ecs_service" "backend_service" {
  name            = "form-app-backend-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.backend_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.backend_sg.id]
    subnets         = [aws_subnet.private[0].id]
  }
}

# --- Application Load Balancer (ALB) and Target Groups
resource "aws_lb" "frontend_alb" {
  name               = "form-app-frontend-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public[0].id, aws_subnet.public[1].id]
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "frontend_tg" {
  name        = "form-app-frontend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.app_vpc.id
  target_type = "ip"
}
# --- Backend Target Group
resource "aws_lb_target_group" "backend_tg" {
  name        = "form-app-backend-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.app_vpc.id
  target_type = "ip"
}
resource "aws_lb_listener" "frontend_listener" {
  load_balancer_arn = aws_lb.frontend_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

# --- ALB Listener Rules for Path-Based Routing
resource "aws_lb_listener_rule" "backend_rule" {
  listener_arn = aws_lb_listener.alb_listener.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]  # Any path starting with /api goes to backend
    }
  }
# --- ALB Listener Rules for Path-Based Routing
resource "aws_lb_listener_rule" "backend_rule" {
  listener_arn = aws_lb_listener.frontend_listener.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]  # Any path starting with /api goes to backend
    }
  }
}}
