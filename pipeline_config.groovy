// Pipeline configuration for SpringPetClinic using shared JTE terraform library
libraries {
    kubernetes
    git
    terraform {
        project_name = "petclinic"
        version = "1.5"
        container_name = "terraform"
        auto_approve = false
        allowed_environments = ['dev', 'staging', 'prod']
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
