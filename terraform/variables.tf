# --- AWS Region
variable "aws_region" {
  description = "The AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"
}

# --- Public ECR Registry Alias
variable "ecr_registry_alias" {
  description = "The alias for your Public ECR registry."
  type        = string
}

