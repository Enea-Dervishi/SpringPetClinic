# DXClient Library Testing Setup

This guide explains how to test the DXClient library using the SpringPetClinic project in your local cluster.

## Prerequisites

1. **JTE Library Setup**: Ensure your Jenkins instance can access the JTE library at `/home/enea/workspace/jte_lib`
2. **Kubernetes Cluster**: k3d cluster running (as per SpringPetClinic setup)
3. **Jenkins with JTE Plugin**: Jenkins with Jenkins Templating Engine plugin installed

## Setup Steps

### 1. Jenkins Credentials Setup

Create the following credentials in Jenkins (Dashboard → Manage Jenkins → Credentials):

```bash
# Navigate to Jenkins credentials page
# Add these credentials with these IDs:

- Credential ID: dx-test-username
  Type: Secret text
  Secret: testuser
  Description: DXClient test username

- Credential ID: dx-test-password  
  Type: Secret text
  Secret: testpass
  Description: DXClient test password

- Credential ID: dx-admin-password
  Type: Secret text
  Secret: your-real-dx-password (for production use)
  Description: DXClient admin password
```

### 2. JTE Configuration

Update your Jenkins JTE configuration to point to the library:

```groovy
// In Jenkins → Configure System → Jenkins Templating Engine
// Library Sources:
[
    $class: 'SCMLibraryProvider',
    scm: [
        $class: 'GitSCM',
        branches: [[name: 'springPetClinic']],
        userRemoteConfigs: [[url: '/home/enea/workspace/jte_lib']]
    ]
]
```

### 3. Running the Tests

#### Option A: Full Integration Test
```bash
# Use the comprehensive test pipeline
cd /home/enea/playground/SpringPetClinic
# Create a new Jenkins job that uses Jenkinsfile.dxclient-test
```

#### Option B: Individual Command Testing
```bash
# Run the test script locally
cd /home/enea/playground/SpringPetClinic
groovy test-dxclient.groovy
```

#### Option C: Add to Existing Pipeline
```groovy
// Add this stage to your existing Jenkinsfile.jte
stage('Test DXClient') {
    dxclient.xmlaccess {
        hostname = 'mock-dx-server.petclinic-dev.svc.cluster.local'
        dxUsername = credentials('dx-test-username')
        dxPassword = credentials('dx-test-password')
        dxProtocol = 'http'
        dxPort = '9080'
        xmlFile = '/tmp/test-config.xml'
    }
}
```

## Test Scenarios

### 1. Mock Server Testing
The test setup includes a mock DX server that:
- Runs as nginx in your k3d cluster
- Responds to HTTP requests on port 9080
- Simulates basic DX server endpoints
- Allows testing without real DX infrastructure

### 2. Command Validation Testing
Tests include:
- **Configuration validation**: Required parameters check
- **Command building**: Proper argument construction  
- **Container execution**: DXClient container functionality
- **Error handling**: Missing parameters, invalid commands
- **Legacy compatibility**: Backward compatibility with existing pipelines

### 3. Security Testing
- Credential injection from Jenkins credential store
- Password masking in logs
- Secure parameter passing

## Available DXClient Commands for Testing

| Command | Test File | Purpose |
|---------|-----------|---------|
| `deploy_application` | `deploy_application.groovy` | Deploy EAR files |
| `deploy_theme` | `deploy_theme.groovy` | Deploy WebDAV themes |
| `xmlaccess` | `xmlaccess.groovy` | Execute XMLAccess scripts |
| `wcm_library` | `wcm_library.groovy` | WCM library operations |
| `livesync_theme` | `livesync_theme.groovy` | Live theme sync |
| `dxclient_invoke` | `dxclient_invoke.groovy` | Legacy command interface |

## Troubleshooting

### Common Issues

1. **Library Not Found**
   ```
   ERROR: No such DSL method 'dxclient'
   ```
   **Solution**: Verify JTE library source configuration in Jenkins

2. **Container Image Issues**
   ```
   ERROR: Unable to find image 'hclcr.io/dx-public/dxclient:v95_CF223_20240925-1911'
   ```
   **Solution**: Ensure your cluster can pull from HCL container registry

3. **Credential Access Issues**
   ```
   ERROR: Missing required DXClient parameters: dxPassword
   ```
   **Solution**: Check Jenkins credentials are properly configured

4. **Mock Server Connection**
   ```
   ERROR: Connection refused to mock-dx-server
   ```
   **Solution**: Ensure mock server is deployed and running in the cluster

### Validation Commands

```bash
# Check if mock server is running
kubectl get pods -n petclinic-dev | grep mock-dx-server

# Test mock server response
kubectl exec -n petclinic-dev deployment/mock-dx-server -- curl localhost/wps

# Check DXClient container availability
docker pull hclcr.io/dx-public/dxclient:v95_CF223_20240925-1911
```

## Production Considerations

When moving to production:

1. **Replace mock credentials** with real DX server credentials
2. **Update hostname** to point to actual DX server
3. **Configure proper SSL/TLS** settings for production DX servers
4. **Set up proper RBAC** for container execution permissions
5. **Configure artifact archiving** for deployment outputs

## Example Production Configuration

```groovy
// Production pipeline_config.groovy
libraries {
    dxclient {
        hostname = 'dx-prod.yourcompany.com'
        dxUsername = credentials('dx-prod-username') 
        dxPassword = credentials('dx-prod-password')
        dxProtocol = 'https'
        dxPort = '443'
        dxContextRoot = '/wps'
        virtualPortalContext = 'portal'
        container_name = 'dxclient'
    }
}
```