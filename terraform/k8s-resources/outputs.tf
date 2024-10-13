# outputs.tf in k8s-resources directory

output "eks_cluster_data" {
  value = data.aws_eks_cluster.cluster
}

output "kubeconfig_command" {
  description = "Command to update kubeconfig for kubectl access"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${data.terraform_remote_state.eks.outputs.cluster_name}"
}
