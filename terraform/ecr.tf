# Create the frontend repository in Public ECR
resource "null_resource" "create_public_ecr_frontend" {
  # This provisioner creates the repository when the resource is created
  provisioner "local-exec" {
    command = "aws ecr-public create-repository --repository-name form-app-frontend"
  }

  # This provisioner deletes the repository when the resource is destroyed
  provisioner "local-exec" {
    when    = destroy
    command = "aws ecr-public delete-repository --repository-name form-app-frontend --force"
  }
}

# Create the backend repository in Public ECR
resource "null_resource" "create_public_ecr_backend" {
  # This provisioner creates the repository when the resource is created
  provisioner "local-exec" {
    command = "aws ecr-public create-repository --repository-name form-app-backend"
  }

  # This provisioner deletes the repository when the resource is destroyed
  provisioner "local-exec" {
    when    = destroy
    command = "aws ecr-public delete-repository --repository-name form-app-backend --force"
  }
}


