# main.tf in k8s-resources directory

data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = "../eks-cluster/terraform.tfstate"
  }
}

provider "aws" {
    region = var.aws_region
}

data "aws_eks_cluster" "cluster" {
    name = data.terraform_remote_state.eks.outputs.cluster_name
}

# AUTHENTICATE KUBERNETES PROVIDER TO EKS CLUSTER

provider "kubernetes" {
    host           = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "aws"
        args = [
            "eks",
            "get-token",
            "--cluster-name",
            data.aws_eks_cluster.cluster.id
        ]
  }
} 

