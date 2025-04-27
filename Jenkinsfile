pipeline {
    agent any
    
    parameters {
        string(name: 'USER_NAME', description: 'Your full name')
        string(name: 'USER_EMAIL', description: 'Your email address')
        string(name: 'PET_NAME', description: 'Your pet\'s name')
        choice(name: 'PET_TYPE', choices: ['Cat', 'Dog', 'Bird', 'Other'], description: 'Type of pet')
        string(name: 'ENVIRONMENT', defaultValue: 'dev', description: 'Environment to deploy to (dev/staging/prod)')
    }
    
    environment {
        GITHUB_USERNAME = 'Enea-Dervishi'
        DOCKER_IMAGE = "ghcr.io/${GITHUB_USERNAME}/petclinic:${params.ENVIRONMENT}-${BUILD_NUMBER}"
    }
    
    stages {
        stage('User Input Validation') {
            steps {
                script {
                    echo "Validating user input for ${params.USER_NAME}'s pet ${params.PET_NAME}"

                    if (!params.USER_NAME?.trim()) {
                        error "User name cannot be empty"
                    }
                    if (params.USER_NAME.split().size() < 2) {
                        error "Please provide both first and last name"
                    }
                    
                    // Email validation
                    if (!params.USER_EMAIL?.trim()) {
                        error "Email cannot be empty"
                    }
                    if (!params.USER_EMAIL.matches('^[A-Za-z0-9+_.-]+@(.+)$')) {
                        error "Invalid email format"
                    }
                    
                    // Pet name validation
                    if (!params.PET_NAME?.trim()) {
                        error "Pet name cannot be empty"
                    }
                    if (params.PET_NAME.length() < 2) {
                        error "Pet name must be at least 2 characters long"
                    }
                    
                    // Environment validation
                    if (!['dev', 'staging', 'prod'].contains(params.ENVIRONMENT)) {
                        error "Environment must be one of: dev, staging, prod"
                    }
                    
                    // Additional validations based on environment
                    if (params.ENVIRONMENT == 'prod') {
                        if (!params.USER_EMAIL.endsWith('@company.com')) {
                            error "Production environment requires company email"
                        }
                        if (params.PET_TYPE == 'Other') {
                            error "Production environment does not support 'Other' pet type"
                        }
                    }
                    
                    echo "All validations passed successfully"
                }
            }
        }
        
        stage('Build & Test') {
            steps {
                sh 'chmod +x ./mvnw'
                sh './mvnw clean package'
                sh './mvnw test'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${DOCKER_IMAGE} ."
                }
            }
        }
        
        stage('Push to GitHub Container Registry') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'github-pat', usernameVariable: 'GITHUB_USERNAME', passwordVariable: 'GITHUB_TOKEN')]) {
                        sh "echo ${GITHUB_TOKEN} | docker login ghcr.io -u ${GITHUB_USERNAME} --password-stdin"
                        sh "docker push ${DOCKER_IMAGE}"
                    }
                }
            }
        }
        
        stage('Deploy & Register') {
            steps {
                script {
                    // Deploy the application using Docker
                    sh "docker run -d -p 8080:8080 --name petclinic-${params.ENVIRONMENT} ${DOCKER_IMAGE}"
                    
                    // Wait for application to start
                    sleep(time: 30, unit: 'SECONDS')
                    
                    // Register the new user and pet using the application's API
                    sh """
                        curl -X POST "http://localhost:8080/api/owners" \
                        -H "Content-Type: application/json" \
                        -d '{
                            "firstName": "${params.USER_NAME.split()[0]}",
                            "lastName": "${params.USER_NAME.split()[1] ?: ''}",
                            "email": "${params.USER_EMAIL}",
                            "pets": [{
                                "name": "${params.PET_NAME}",
                                "type": "${params.PET_TYPE}"
                            }]
                        }'
                    """
                }
            }
        }

        stage('Terraform Infrastructure') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    sh "terraform plan -var='tf_env=${params.ENVIRONMENT}'"
                    sh "terraform apply -auto-approve -var='tf_env=${params.ENVIRONMENT}'"
                }
            }
        }
    }
    
    post {
        always {
            // Cleanup
            sh "docker stop petclinic-${params.ENVIRONMENT} || true"
            sh "docker rm petclinic-${params.ENVIRONMENT} || true"
            echo "Pipeline completed for ${params.USER_NAME}'s pet ${params.PET_NAME}"
        }
        success {
            echo "Successfully registered ${params.PET_NAME} for ${params.USER_NAME}"
            echo "Docker image pushed: ${DOCKER_IMAGE}"
        }
        failure {
            echo "Failed to complete the registration process"
        }
    }
}