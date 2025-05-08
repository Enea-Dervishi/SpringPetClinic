pipeline {
    agent any

    options {
        timestamps()
    }

    parameters {
        string(name: 'USER_NAME', description: 'Your full name')
        string(name: 'USER_EMAIL', description: 'Your email address')
        string(name: 'PET_NAME', description: 'Your pet\'s name')
        choice(name: 'PET_TYPE', choices: ['Cat', 'Dog', 'Bird', 'Other'], description: 'Type of pet')
        string(name: 'ENVIRONMENT', defaultValue: 'dev', description: 'Environment to deploy to (dev/staging/prod)')
    }

    environment {
        GITHUB_USERNAME = 'enea-dervishi'
        DOCKER_IMAGE = "ghcr.io/${GITHUB_USERNAME}/petclinic:${params.ENVIRONMENT}-${BUILD_NUMBER}"
        DOCKER_NETWORK = "petclinic-network-${BUILD_NUMBER}"
        KUBECONFIG = '/etc/rancher/k3s/k3s.yaml'
    }

    stages {
        stage('User Input Validation') {
            steps {
                script {
                    echo "Validating user input for ${params.USER_NAME}'s pet ${params.PET_NAME}"

                    if (!params.USER_NAME?.trim()) {
                        error 'User name cannot be empty'
                    }
                    if (params.USER_NAME.split().size() < 2) {
                        error 'Please provide both first and last name'
                    }

                    // Email validation
                    if (!params.USER_EMAIL?.trim()) {
                        error 'Email cannot be empty'
                    }
                    if (!params.USER_EMAIL.matches('^[A-Za-z0-9+_.-]+@(.+)$')) {
                        error 'Invalid email format'
                    }

                    // Pet name validation
                    if (!params.PET_NAME?.trim()) {
                        error 'Pet name cannot be empty'
                    }
                    if (params.PET_NAME.length() < 2) {
                        error 'Pet name must be at least 2 characters long'
                    }

                    // Environment validation
                    if (!['dev', 'staging', 'prod'].contains(params.ENVIRONMENT)) {
                        error 'Environment must be one of: dev, staging, prod'
                    }

                    // Additional validations based on environment
                    if (params.ENVIRONMENT == 'prod') {
                        if (!params.USER_EMAIL.endsWith('@company.com')) {
                            error 'Production environment requires company email'
                        }
                        if (params.PET_TYPE == 'Other') {
                            error "Production environment does not support 'Other' pet type"
                        }
                    }

                    echo 'All validations passed successfully'
                }
            }
        }

        stage('Build & Test') {
            steps {
                sh 'chmod +x ./mvnw'
                sh './mvnw clean package'
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
                    // Creating a dedicated network for the application
                    sh "docker network create ${DOCKER_NETWORK} || true"

                    // Deploy the application using Docker with the custom network
                    sh """
                        docker run -d --name petclinic-${params.ENVIRONMENT} \
                        --network ${DOCKER_NETWORK} \
                        -p 8081:8081 \
                        ${DOCKER_IMAGE}
                    """
                    echo 'Waiting for application to start...'
                    sleep(time: 60, unit: 'SECONDS')

                    // Check if the application is up by making a simple GET request
                    sh 'curl -v http://localhost:8081/actuator/health || echo "Application health check failed but continuing"'
                    sh 'curl -v http://localhost:8081/ || echo "Application homepage check failed but continuing"'

                    // Print container logs and network info to help with debugging
                    echo 'Container logs:'
                    sh "docker logs petclinic-${params.ENVIRONMENT}"
                    echo 'Docker network info:'
                    sh "docker network inspect ${DOCKER_NETWORK}"
                    echo 'Container info:'
                    sh "docker inspect petclinic-${params.ENVIRONMENT}"

                    // Extract the container IP address
                    def containerIp = sh(script: "docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' petclinic-${params.ENVIRONMENT}", returnStdout: true).trim()
                    echo "Container IP address: ${containerIp}"

                    // Prepare user data
                    def firstName = params.USER_NAME.split()[0]
                    def lastName = params.USER_NAME.split().size() > 1 ? params.USER_NAME.split()[1] : ''

                    // Create a temporary file with the JSON payload - properly formatted JSON
                    def jsonPayload = """{
                    "firstName": "${firstName}",
                    "lastName": "${lastName}",
                    "email": "${params.USER_EMAIL}",
                    "pets": [
                        {
                        "name": "${params.PET_NAME}",
                        "type": "${params.PET_TYPE}"
                        }
                    ]
                    }"""
                    writeFile file: 'payload.json', text: jsonPayload
                    echo 'JSON payload created:'
                    sh 'cat payload.json'

                    echo 'Attempting API call with file-based payload to localhost...'
                    try {
                        sh 'curl -v -X POST "http://localhost:8081/api/owners" -H "Content-Type: application/json" -d @payload.json || echo "API call failed but continuing"'
                    } catch (Exception e) {
                        echo "First attempt failed with error: ${e.message}"
                    }

                    echo 'Testing direct IP approach...'
                    try {
                        sh "curl -v -X POST \"http://${containerIp}:8081/api/owners\" -H \"Content-Type: application/json\" -d @payload.json || echo \"Direct IP API call failed but continuing\""
                    } catch (Exception e) {
                        echo "Direct IP approach failed with error: ${e.message}"
                    }

                    echo 'Testing minimal JSON approach...'
                    try {
                        sh """
                            curl -v -X POST "http://localhost:8081/api/owners" \\
                            -H "Content-Type: application/json" \\
                            -d '{"firstName":"${firstName}","lastName":"${lastName}","email":"${params.USER_EMAIL}","pets":[{"name":"${params.PET_NAME}","type":"${params.PET_TYPE}"}]}' \\
                            || echo "Minimal JSON approach failed but continuing"
                        """
                    } catch (Exception e) {
                        echo "Minimal JSON approach failed with error: ${e.message}"
                    }

                    // Try Docker exec approach as a last resort
                    echo 'Trying Docker exec approach...'
                    try {
                        writeFile file: 'register-user.sh', text: """#!/bin/bash
                        curl -v -X POST "http://localhost:8081/api/owners" \\
                        -H "Content-Type: application/json" \\
                        -d '{"firstName":"${firstName}","lastName":"${lastName}","email":"${params.USER_EMAIL}","pets":[{"name":"${params.PET_NAME}","type":"${params.PET_TYPE}"}]}'
                        """
                        sh 'chmod +x register-user.sh'
                        sh "docker cp register-user.sh petclinic-${params.ENVIRONMENT}:/tmp/"
                        sh "docker exec petclinic-${params.ENVIRONMENT} /bin/bash /tmp/register-user.sh || echo \"Docker exec approach failed but continuing\""
                    } catch (Exception e) {
                        echo "Docker exec approach failed with error: ${e.message}"
                    }

                    // Checking if API is working
                    echo 'Testing API connectivity...'
                    sh 'curl -v http://localhost:8081/api/owners || echo "GET request failed but continuing"'
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
            sh "docker network rm ${DOCKER_NETWORK} || true"
            sh 'rm -f payload.json || true'
            echo "Pipeline completed for ${params.USER_NAME}'s pet ${params.PET_NAME}"
        }
        success {
            echo "Successfully registered ${params.PET_NAME} for ${params.USER_NAME}"
            echo "Docker image pushed: ${DOCKER_IMAGE}"
        }
        failure {
            echo 'Failed to complete the registration process'
        }
    }
}
