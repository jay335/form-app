# --- Create CloudWatch log groups for frontend and backend tasks
resource "aws_cloudwatch_log_group" "frontend_log_group" {
  name = "/ecs/form-app-frontend"
  retention_in_days = 7

  tags = {
    Name = "form-app-frontend-logs"
  }
}

resource "aws_cloudwatch_log_group" "backend_log_group" {
  name = "/ecs/form-app-backend"
  retention_in_days = 7

  tags = {
    Name = "form-app-backend-logs"
  }
}

# --- Simplified CloudWatch monitoring
# Note: Full Prometheus/Grafana setup on Fargate requires a more advanced
# service discovery mechanism and is outside the scope of this file.
# For local testing, using CloudWatch metrics is a good starting point.
# You can later manually configure a Prometheus scraper on a separate EC2 instance
# to pull metrics from your ECS tasks, using CloudWatch Container Insights.

