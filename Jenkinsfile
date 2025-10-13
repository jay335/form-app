pipeline {
    agent any

    environment {
        // Use your Public ECR registry alias directly. AWS_ACCOUNT_ID and AWS_REGION are not needed for this.
        ECR_REGISTRY_ALIAS = 's6n5s7b0'
        ECR_FRONTEND = "public.ecr.aws/${ECR_REGISTRY_ALIAS}/form-app-frontend"
        ECR_BACKEND = "public.ecr.aws/${ECR_REGISTRY_ALIAS}/form-app-backend"
        // Since you are using Public ECR, you can also define the public ECR login URL
        ECR_PUBLIC_LOGIN_URL = "public.ecr.aws"
        // Also needed for the login command, although AWS_ACCOUNT_ID is not part of the URL
        AWS_ACCOUNT_ID = '776401291780'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/jay335/form-app.git', credentialsId: 'github-pat'
            }
        }

        stage('Authenticate to Public ECR') {
            steps {
                script {
                    // Authenticate to the Public ECR registry URL
                    sh "aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${ECR_PUBLIC_LOGIN_URL}"
                }
            }
        }
        
        stage('Build and Push Frontend') {
            steps {
                script {
                    dir('frontend') {
                        sh "docker build -t form-app-frontend:latest ."
                    }
                    sh "docker tag form-app-frontend:latest ${ECR_FRONTEND}:latest"
                    sh "docker push ${ECR_FRONTEND}:latest"
                }
            }
        }

        stage('Build and Push Backend') {
            steps {
                script {
                    dir('backend') {
                        sh "docker build -t form-app-backend:latest ."
                    }
                    sh "docker tag form-app-backend:latest ${ECR_BACKEND}:latest"
                    sh "docker push ${ECR_BACKEND}:latest"
                }
            }
        }

        stage('Deploy with Terraform') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                }
            }
        }
    }
}
