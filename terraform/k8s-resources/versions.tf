# versions.tf in eks-cluster directory

terraform {
    required_version = ">=1.9.5"
    required_providers {
    aws = {
            source = "hashicorp/aws"
            version = "~>5.68"
        }
    kubernetes = {
        source = "hashicorp/kubernetes"
        version = "~>2.18"
    }
    }
}