# --- Output the ALB DNS Name for accessing the frontend service
output "frontend_alb_dns" {
  description = "The DNS name of the Application Load Balancer for the frontend service."
  value       = aws_lb.frontend_alb.dns_name
}

