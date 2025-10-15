// Pipeline configuration for SpringPetClinic using shared JTE terraform library
libraries {
    kubernetes
    git
    kubectl {
        image = 'bitnami/kubectl=1.30-debian-12'
            createNamespace {
            command = ['create'],
            type = 'namespace',
            name = 'petclinic-dev',
            flags = '--dry-run=client -o yaml | kubectl apply -f -'
            }
            applyOverlay {
            command = 'apply',
            type = '',
            name = '',
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
        auto_approve = true  // Allow auto-approve for dev
    }
    staging {
        terraform_workspace = "staging"
        working_directory = "terraform"
        auto_approve = false
    }
    prod {
        terraform_workspace = "prod"
        working_directory = "terraform"
        auto_approve = false  // Always require manual approval for prod
    }
}
