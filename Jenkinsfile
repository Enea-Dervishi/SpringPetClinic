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
                    // Deploy ArgoCD and generate manifests using Terraform
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
                                    -var="k8s_config_path=\$HOME/.kube/config" \\
                                    -var="build_number=${BUILD_NUMBER}"
                                terraform apply -auto-approve \\
                                    -var="ghcr_username=\${GITHUB_USERNAME}" \\
                                    -var="ghcr_token=\${GITHUB_TOKEN}" \\
                                    -var="k8s_config_path=\$HOME/.kube/config" \\
                                    -var="build_number=${BUILD_NUMBER}"
                            """
                        }
                    }

                    // Commit and push generated manifests to trigger ArgoCD sync
                    withCredentials([usernamePassword(credentialsId: 'github-pat', usernameVariable: 'GITHUB_USERNAME', passwordVariable: 'GITHUB_TOKEN')]) {
                        sh """
                            # Configure git
                            git config user.name "Jenkins CI"
                            git config user.email "jenkins@petclinic.local"
                            
                            # Add generated manifests
                            git add k8s-manifests/environments/dev/
                            
                            # Check if there are changes to commit
                            if git diff --staged --quiet; then
                                echo "No changes to commit"
                            else
                                git commit -m "Update dev manifests for build ${BUILD_NUMBER}"
                                git push https://\${GITHUB_USERNAME}:\${GITHUB_TOKEN}@github.com/enea-dervishi/SpringPetClinic.git HEAD:main
                                echo "Pushed manifest changes to trigger ArgoCD sync"
                            fi
                        """
                    }

                    // Wait for ArgoCD to sync the application
                    timeout(10) {
                        sh """
                            # Wait for ArgoCD to be ready
                            kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd || true
                            
                            # Login to ArgoCD CLI (using port-forward in background)
                            kubectl port-forward svc/argocd-server -n argocd 8082:443 --address=0.0.0.0 &
                            sleep 10
                            
                            # Get ArgoCD admin password
                            ARGOCD_PASSWORD=\$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
                            
                            # Login to ArgoCD
                            argocd login localhost:8082 --username admin --password \$ARGOCD_PASSWORD --insecure
                            
                            # Sync the application
                            argocd app sync petclinic-dev --timeout 300
                            
                            # Wait for sync to complete
                            argocd app wait petclinic-dev --timeout 300
                            
                            echo "ArgoCD sync completed successfully"
                        """
                    }
        
                    // Wait for application to be ready
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
                    
                    // Check if owner already exists
                    def searchResponse = sh(
                        script: """
                            curl -s "http://localhost:${env.NODE_PORT}/owners/search?lastName=${URLEncoder.encode(lastName, 'UTF-8')}"
                        """,
                        returnStdout: true
                    ).trim()
                    
                    echo "Search response: ${searchResponse}"
                    
                    // Parse the search results
                    def existingOwner = false
                    def ownerId = null
                    
                    // Convert search response to single line and escape quotes for proper parsing
                    def normalizedResponse = searchResponse.replaceAll('\n', ' ').replaceAll('\r', '')
                    echo "Normalized search response: ${normalizedResponse}"
                    
                    // Check if any owner matches all our criteria
                    if (normalizedResponse.contains('"firstName":"' + firstName + '"')) {
                        echo "Found owner with matching first name, checking other details..."
                        
                        // Extract all owner IDs for owners with matching first name
                        def ownerIds = []
                        def idPattern = /"id":(\d+)/
                        def matcher = normalizedResponse =~ idPattern
                        while (matcher.find()) {
                            ownerIds.add(matcher.group(1))
                        }
                        
                        // Check each owner's details
                        for (String id : ownerIds) {
                            def ownerDetailsResponse = sh(
                                script: """
                                    curl -s "http://localhost:${env.NODE_PORT}/owners/${id}"
                                """,
                                returnStdout: true
                            ).trim()
                            
                            echo "Checking owner ${id} details: ${ownerDetailsResponse}"
                            
                            // Check if all fields match
                            if (ownerDetailsResponse.contains('"firstName":"' + firstName + '"') &&
                                ownerDetailsResponse.contains('"lastName":"' + lastName + '"') &&
                                ownerDetailsResponse.contains('"address":"' + params.USER_ADDRESS + '"') &&
                                ownerDetailsResponse.contains('"city":"' + params.USER_CITY + '"') &&
                                ownerDetailsResponse.contains('"telephone":"' + params.USER_TELEPHONE + '"')) {
                                
                                existingOwner = true
                                ownerId = id
                                echo "Found exact match with owner ID: ${ownerId}"
                                
                                // Check if this owner has a pet with the same name
                                if (ownerDetailsResponse.contains('"name":"' + params.PET_NAME + '"')) {
                                    error "Owner already has a pet named ${params.PET_NAME}"
                                }
                                break
                            }
                        }
                    }
                    
                    if (existingOwner && ownerId) {
                        echo "Using existing owner with ID: ${ownerId}"
                    } else {
                        // Create new owner if not found
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
                        
                        // Extract owner ID using simple string parsing
                        ownerFormOutput.split('\n').each { line ->
                            if (line.contains('Location:') && line.contains('/owners/')) {
                                ownerId = line.substring(line.lastIndexOf('/') + 1).trim()
                                echo "Successfully created new owner with ID: ${ownerId}"
                            }
                        }
                        
                        if (!ownerId) {
                            error "Failed to extract owner ID from the response"
                        }
                    }
                    
                    // Now add a pet using form submission
                    def petFormOutput = sh(
                        script: """
                            curl -i -s -X POST "http://localhost:${env.NODE_PORT}/owners/${ownerId}/pets/new" \\
                                -H "Content-Type: application/x-www-form-urlencoded" \\
                                -d "name=${URLEncoder.encode(params.PET_NAME ?: 'Pet', 'UTF-8')}" \\
                                -d "birthDate=${URLEncoder.encode(params.PET_BIRTH_DATE?.toString()?.replace('/', '-') ?: '2020-01-01', 'UTF-8')}" \\
                                -d "type=${URLEncoder.encode(params.PET_TYPE?.toString()?.toLowerCase() ?: 'cat', 'UTF-8')}"
                        """,
                        returnStdout: true
                    ).trim()
                    
                    echo "Pet form submission complete output: ${petFormOutput}"
                    
                    // Check if the pet was added successfully (look for a redirect to the owner page)
                    if (petFormOutput.contains("302") && petFormOutput.contains("/owners/${ownerId}")) {
                        echo "Successfully registered pet ${params.PET_NAME} for owner ${params.USER_NAME} with ID ${ownerId}"
                    } else {
                        error "Failed to add pet for owner with ID ${ownerId}"
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
