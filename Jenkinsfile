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

                    // Wait for application to be ready
                    timeout(5) {
                        waitUntil {
                            script {
                                def response = sh(
                                    script: "curl -s -f http://localhost:${env.NODE_PORT}/manage/health || true",
                                    returnStdout: true
                                ).trim()
                                
                                return response.contains('"status":"UP"')
                            }
                        }
                    }

                    // Register owner and pet
                    def firstName = params.USER_NAME.split()[0]
                    def lastName = params.USER_NAME.split()[1..-1].join(' ')
                    def petTypeId = [cat:1, dog:2, lizard:3, snake:4, bird:5, hamster:6][params.PET_TYPE]

                    // Add owner
                    def ownerJson = groovy.json.JsonOutput.toJson([
                        firstName: firstName,
                        lastName: lastName,
                        address: params.USER_ADDRESS,
                        city: params.USER_CITY,
                        telephone: params.USER_TELEPHONE
                    ])
                    
                    def ownerResponse = sh(
                        script: "curl -s -X POST 'http://localhost:${env.NODE_PORT}/api/owners' -H 'Content-Type: application/json' -d '${ownerJson}'",
                        returnStdout: true
                    ).trim()

                    def ownerId = readJSON(text: ownerResponse).id

                    // Add pet
                    def petJson = groovy.json.JsonOutput.toJson([
                        name: params.PET_NAME,
                        birthDate: params.PET_BIRTH_DATE,
                        typeId: petTypeId
                    ])

                    sh "curl -s -X POST 'http://localhost:${env.NODE_PORT}/api/owners/${ownerId}/pets' -H 'Content-Type: application/json' -d '${petJson}'"
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
