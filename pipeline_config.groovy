libraries {
    kubernetes
    git
    maven {
        containerImage = 'maven:3.6-ibmjava-alpine'
        mvnPackage{
            stageName = 'Maven Build'
            phases = ['clean' , 'package']
            options = ['-Dmaven.install.skip=true']
            revision = '$BUILD_TIMESTAMP'
        }
        publish {
            stageName = 'Maven Deploy'
            phases = ['deploy']
            options = ['-DskipTests', '-Dmaven.deploy.uniqueVersion=false', '-DuniqueVersion=false', '-Dmaven.install.skip=true']
            revision = '$BUILD_TIMESTAMP'
        }
    }
    kubectl {
        containerImage = 'alpine/k8s:1.30.0'
        createNamespace {
            command = 'create'
            type = 'namespace'
            name = 'petclinic-dev'
            flags = '--save-config'
        }
        applyOverlay {      
            command = 'apply'
            type = ''
            name = ''
            flags = '-k k8s/overlays/dev'
        }
    }
    terraform {
        project_name = "petclinic"
        version = "1.5"
        container_name = "terraform"
        auto_approve = true
        environment = "dev"
        allowed_environments = "dev"
        directory_pattern = "environments/\${environment}"
    }
}

application_environments {
    dev {
        terraform_workspace = "dev"
        working_directory = "terraform"
        auto_approve = true
    }
    staging {
        terraform_workspace = "staging"
        working_directory = "terraform"
        auto_approve = false
    }
    prod {
        terraform_workspace = "prod"
        working_directory = "terraform"
        auto_approve = false
    }
}
