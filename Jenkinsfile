pipeline {
    agent any

    options {
        timestamps()
    }

    parameters {
        string(name: 'USER_NAME', description: 'Your full name')
        string(name: 'USER_ADDRESS', description: 'Your address')
        string(name: 'USER_CITY', description: 'Your city')
        string(name: 'USER_TELEPHONE', description: 'Your telephone number')
        string(name: 'PET_NAME', description: 'Your pet\'s name')
        choice(name: 'PET_TYPE', choices: ['cat', 'dog', 'lizard', 'snake', 'bird', 'hamster'], description: 'Type of pet')
        string(name: 'PET_BIRTH_DATE', defaultValue: '2020/01/01', description: 'Pet\'s birth date (YYYY/MM/DD)')
        string(name: 'ENVIRONMENT', defaultValue: 'dev', description: 'Environment to deploy to (dev/staging/prod)')
    }

    environment {
        GITHUB_USERNAME = 'enea-dervishi'
        DOCKER_IMAGE = "ghcr.io/${GITHUB_USERNAME}/petclinic:${params.ENVIRONMENT}-${BUILD_NUMBER}"
        APP_PORT = '8081'
        NODE_PORT = '30081'
    }

    stages {
        stage('Validate Input') {
            steps {
                script {
                    // Name validation
                    if (!params.USER_NAME?.trim() || params.USER_NAME.split().size() < 2) {
                        error 'Please provide both first and last name'
                    }

                    // Required fields validation
                    def requiredFields = [
                        'USER_ADDRESS': params.USER_ADDRESS,
                        'USER_CITY': params.USER_CITY,
                        'USER_TELEPHONE': params.USER_TELEPHONE,
                        'PET_NAME': params.PET_NAME
                    ]
                    
                    requiredFields.each { field, value ->
                        if (!value?.trim()) {
                            error "${field.toLowerCase().replace('_', ' ')} cannot be empty"
                        }
                    }

                    // Format validations
                    if (!params.USER_TELEPHONE.matches('^[0-9]{10}$')) {
                        error 'Telephone must be 10 digits'
                    }
                    if (!params.PET_BIRTH_DATE.matches('^\\d{4}/\\d{2}/\\d{2}$')) {
                        error 'Birth date must be in YYYY/MM/DD format'
                    }
                    if (!['dev', 'staging', 'prod'].contains(params.ENVIRONMENT)) {
                        error 'Environment must be one of: dev, staging, prod'
                    }
                }
            }
        }

        stage('Build & Test') {
            steps {
                sh '''
                    chmod +x ./mvnw
                    ./mvnw clean package
                '''
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'github-pat', usernameVariable: 'GITHUB_USERNAME', passwordVariable: 'GITHUB_TOKEN')]) {
                        sh """
                            echo \${GITHUB_TOKEN} | docker login ghcr.io -u \${GITHUB_USERNAME} --password-stdin
                            docker build -t ${DOCKER_IMAGE} .
                            docker push ${DOCKER_IMAGE}
                        """
                    }
                }
            }
        }

        stage('Deploy & Register') {
            steps {
                script {
                    // Deploy to k3d using Terraform
                    withCredentials([usernamePassword(credentialsId: 'github-pat', usernameVariable: 'GITHUB_USERNAME', passwordVariable: 'GITHUB_TOKEN')]) {
                        dir('terraform/environments/dev') {
                            // Copy k3d config to Jenkins workspace
                            sh """
                                mkdir -p \$HOME/.kube
                                cp /etc/rancher/k3s/jenkins-k3s.yaml \$HOME/.kube/config
                                chmod 600 \$HOME/.kube/config
                                
                                rm -f .terraform.lock.hcl || true
                                terraform init -upgrade
                                terraform plan \\
                                    -var="ghcr_username=\${GITHUB_USERNAME}" \\
                                    -var="ghcr_token=\${GITHUB_TOKEN}" \\
                                    -var="k8s_config_path=\$HOME/.kube/config"
                                terraform apply -auto-approve \\
                                    -var="ghcr_username=\${GITHUB_USERNAME}" \\
                                    -var="ghcr_token=\${GITHUB_TOKEN}" \\
                                    -var="k8s_config_path=\$HOME/.kube/config"
                            """
                        }
                    }
        
                    // Wait for application to be ready with better error handling
                    timeout(5) {
                        waitUntil {
                            script {
                                try {
                                    def response = sh(
                                        script: "curl -s -f http://localhost:${env.NODE_PORT}/manage/health || echo 'failed'",
                                        returnStdout: true
                                    ).trim()
                                    
                                    echo "Health check response: ${response}"
                                    return response.contains('"status":"UP"')
                                } catch (Exception e) {
                                    echo "Health check exception: ${e.message}"
                                    return false
                                }
                            }
                        }
                    }
        
                    // Define user data
                    def firstName = params.USER_NAME ? params.USER_NAME.split(' ')[0] : 'Default'
                    def lastName = params.USER_NAME && params.USER_NAME.split(' ').size() > 1 ? 
                        params.USER_NAME.split(' ')[1..-1].join(' ') : 'User'
                    
                    // Get pet type string
                    def petType = params.PET_TYPE?.toString()?.toLowerCase() ?: 'cat'
                    
                    // Make sure date is in correct YYYY-MM-DD format
                    def petBirthDate = params.PET_BIRTH_DATE?.toString()?.replace('/', '-') ?: '2020-01-01'
        
                    // Create owner using form submission and capture the complete output with headers
                    def ownerFormOutput = sh(
                        script: """
                            curl -i -s -X POST "http://localhost:${env.NODE_PORT}/owners/new" \\
                                -H "Content-Type: application/x-www-form-urlencoded" \\
                                -d "firstName=${URLEncoder.encode(firstName, 'UTF-8')}" \\
                                -d "lastName=${URLEncoder.encode(lastName, 'UTF-8')}" \\
                                -d "address=${URLEncoder.encode(params.USER_ADDRESS ?: '', 'UTF-8')}" \\
                                -d "city=${URLEncoder.encode(params.USER_CITY ?: '', 'UTF-8')}" \\
                                -d "telephone=${URLEncoder.encode(params.USER_TELEPHONE ?: '', 'UTF-8')}"
                        """,
                        returnStdout: true
                    ).trim()
                    
                    echo "Owner form submission complete output: ${ownerFormOutput}"
                    
                    // Extract owner ID using simple string parsing instead of regex
                    def ownerId = null
                    ownerFormOutput.split('\n').each { line ->
                        if (line.contains('Location:') && line.contains('/owners/')) {
                            ownerId = line.substring(line.lastIndexOf('/') + 1).trim()
                            echo "Successfully extracted owner ID: ${ownerId}"
                        }
                    }
                    
                    if (!ownerId) {
                        error "Failed to extract owner ID from the response"
                    }
                    
                    // Now add a pet using form submission
                    def petFormOutput = sh(
                        script: """
                            curl -i -s -X POST "http://localhost:${env.NODE_PORT}/owners/${ownerId}/pets/new" \\
                                -H "Content-Type: application/x-www-form-urlencoded" \\
                                -d "name=${URLEncoder.encode(params.PET_NAME ?: 'Pet', 'UTF-8')}" \\
                                -d "birthDate=${URLEncoder.encode(petBirthDate, 'UTF-8')}" \\
                                -d "typeId=1"
                        """,
                        returnStdout: true
                    ).trim()
                    
                    echo "Pet form submission complete output: ${petFormOutput}"
                    
                    // Check if the pet was added successfully (look for a redirect to the owner page)
                    if (petFormOutput.contains("302") && petFormOutput.contains("/owners/${ownerId}")) {
                        echo "Successfully registered pet ${params.PET_NAME} for owner ${params.USER_NAME} with ID ${ownerId}"
                    } else {
                        // Try with a different form field for pet type
                        petFormOutput = sh(
                            script: """
                                curl -i -s -X POST "http://localhost:${env.NODE_PORT}/owners/${ownerId}/pets/new" \\
                                    -H "Content-Type: application/x-www-form-urlencoded" \\
                                    -d "name=${URLEncoder.encode(params.PET_NAME ?: 'Pet', 'UTF-8')}" \\
                                    -d "birthDate=${URLEncoder.encode(petBirthDate, 'UTF-8')}" \\
                                    -d "type=${URLEncoder.encode(petType, 'UTF-8')}"
                            """,
                            returnStdout: true
                        ).trim()
                        
                        echo "Second pet form submission complete output: ${petFormOutput}"
                        
                        if (petFormOutput.contains("302") && petFormOutput.contains("/owners/${ownerId}")) {
                            echo "Successfully registered pet ${params.PET_NAME} for owner ${params.USER_NAME} with ID ${ownerId}"
                        } else {
                            error "Failed to add pet for owner with ID ${ownerId}"
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline completed for ${params.USER_NAME}'s pet ${params.PET_NAME}"
        }
        success {
            echo "Successfully registered ${params.PET_NAME} for ${params.USER_NAME}"
        }
        failure {
            echo 'Failed to complete the registration process'
        }
    }
}
