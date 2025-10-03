@Library(['local-jte-lib@main']) _

pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
  - name: limitless
    image: factorysrl/limitlessdx-cli:0.0.8.1
    command: ["sleep"]
    args: ["infinity"]
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "200m"
  - name: terraform
    image: hashicorp/terraform:1.5
    command: ["sleep"]
    args: ["infinity"]
    resources:
      requests:
        memory: "512Mi"
        cpu: "200m"
      limits:
        memory: "1Gi"
        cpu: "500m"
            '''
        }
    }

    parameters {
        choice(
            name: 'CHOOSE_ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Which Environment do you want to deploy to?'
        )
        choice(
            name: 'IMAGE_TAG',
            choices: ['latest', 'dev-4', 'dev-3', 'dev-1', 'dev-91', 'dev-90', 'dev-89', 'staging-88', 'dev-87', 'dev-85', 'dev-84'],
            description: 'Which Docker image version to deploy?'
        )
    }

    environment {
        DOCKER_IMAGE = 'ghcr.io/enea-dervishi/petclinic'
        NAMESPACE = "petclinic-${params.CHOOSE_ENVIRONMENT}"
        GITHUB_TOKEN = credentials('github-token')
    }

    stages {
        stage('Create Namespace & Deploy Application') {
            steps {
                container('limitless') {
                    script {
                        // Create namespace
                        sh "kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -"
                        sh "kubectl delete secret ghcr-secret -n ${NAMESPACE} --ignore-not-found=true"
                        
                        // Create image pull secret
                        withCredentials([string(credentialsId: 'github-token', variable: 'TOKEN')]) {
                            sh '''
                                kubectl create secret docker-registry ghcr-secret \
                                    --docker-server=ghcr.io \
                                    --docker-username=enea-dervishi \
                                    --docker-password=${TOKEN} \
                                    --docker-email=eneadervishi14@gmail.com \
                                    -n ${NAMESPACE}
                            '''
                        }
                        
                        // Deploy application using Kustomize
                        sh '''
                            echo "Deploying application with Kustomize..."
                            kubectl apply -k k8s/overlays/${CHOOSE_ENVIRONMENT}
                            
                            # Update image tag if different from overlay default
                            if [ "${IMAGE_TAG}" != "dev-4" ]; then
                                echo "Updating image tag to ${IMAGE_TAG}..."
                                kubectl set image deployment/petclinic petclinic=${DOCKER_IMAGE}:${IMAGE_TAG} -n ${NAMESPACE}
                            fi
                            
                            echo "Waiting for deployment to complete..."
                            kubectl rollout status deployment/petclinic -n ${NAMESPACE} --timeout=300s
                        '''
                        
                        // Verify deployment
                        sh '''
                            kubectl wait --for=condition=ready pod -l app=petclinic -n ${NAMESPACE} --timeout=120s
                            kubectl get pods,services -l app=petclinic -n ${NAMESPACE}
                        '''
                    }
                }
            }
        }

        stage('Deploy Infrastructure') {
            steps {
                script {
                    // Use JTE Terraform library
                    terraform.init([
                        environment: params.CHOOSE_ENVIRONMENT,
                        container_name: 'terraform'
                    ])
                    
                    terraform.validate([
                        environment: params.CHOOSE_ENVIRONMENT,
                        container_name: 'terraform'
                    ])
                    
                    terraform.plan([
                        environment: params.CHOOSE_ENVIRONMENT,
                        container_name: 'terraform'
                    ])
                    
                    terraform.apply([
                        environment: params.CHOOSE_ENVIRONMENT,
                        container_name: 'terraform',
                        auto_approve: true  // Set to false for manual approval
                    ])
                }
            }
        }

        stage('Health Check') {
            steps {
                container('limitless') {
                    script {
                        sh '''
                            echo "Performing health check..."
                            sleep 15

                            for i in {1..5}; do
                                if curl -f http://petclinic-service.${NAMESPACE}.svc.cluster.local:8085/manage/health 2>/dev/null; then
                                    echo "✅ Application health check passed!"
                                    exit 0
                                fi
                                echo "⏳ Health check attempt $i/5..."
                                sleep 10
                            done
                            
                            echo "❌ Health check failed"
                            exit 1
                        '''
                    }
                }
            }
        }

        stage('Deployment Summary') {
            steps {
                container('limitless') {
                    script {
                        sh '''
                            echo "=== Deployment Summary ==="
                            echo "Environment: ${NAMESPACE}"
                            echo "Image: ${DOCKER_IMAGE}:${IMAGE_TAG}"
                            echo ""
                            echo "=== Kubernetes Resources ==="
                            kubectl get all -l app=petclinic -n ${NAMESPACE}
                            echo ""
                            echo "=== Access Information ==="
                            kubectl get services -n ${NAMESPACE}
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo "🎉 Deployment successful! Application is running in ${params.CHOOSE_ENVIRONMENT} environment."
        }
        failure {
            echo '❌ Deployment failed. Check the logs above for details.'
        }
    }
}