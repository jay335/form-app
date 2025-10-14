pipeline {
    agent any

    environment {
        ECR_REGISTRY_ALIAS = 's6n5s7b0'
        ECR_FRONTEND = "public.ecr.aws/${ECR_REGISTRY_ALIAS}/form-app-frontend"
        ECR_BACKEND = "public.ecr.aws/${ECR_REGISTRY_ALIAS}/form-app-backend"
        ECR_PUBLIC_LOGIN_URL = "public.ecr.aws"
    }

    stages {
        // The initial checkout is handled by the Jenkins job configuration.
        // There is no need for a manual 'Checkout' stage here.

        stage('Authenticate to Public ECR') {
            steps {
                script {
                    withCredentials([aws(credentialsId: 'aws-jenkins-user', roleArn: null)]) {
                        // Authenticate to the Public ECR registry URL
                        sh "aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${ECR_PUBLIC_LOGIN_URL}"
                    }
                }
            }
        }

        stage('Build and Push Frontend') {
            steps {
                script {
                    withCredentials([aws(credentialsId: 'aws-jenkins-user', roleArn: null)]) {
                        dir('frontend') {
                            sh "docker build -t form-app-frontend:latest ."
                        }
                        sh "docker tag form-app-frontend:latest ${ECR_FRONTEND}:latest"
                        sh "docker push ${ECR_FRONTEND}:latest"
                    }
                }
            }
        }

        stage('Build and Push Backend') {
            steps {
                script {
                    withCredentials([aws(credentialsId: 'aws-jenkins-user', roleArn: null)]) {
                        dir('backend') {
                            sh "docker build -t form-app-backend:latest ."
                        }
                        sh "docker tag form-app-backend:latest ${ECR_BACKEND}:latest"
                        sh "docker push ${ECR_BACKEND}:latest"
                    }
                }
            }
        }

        stage('Deploy with Terraform') {
            steps {
                script {
                    withCredentials([aws(credentialsId: 'aws-jenkins-user', roleArn: null)]) {
                        dir('terraform') {
                            sh 'terraform init'
                            sh 'terraform apply -auto-approve'
                        }
                    }
                }
            }
        }
    }
}

