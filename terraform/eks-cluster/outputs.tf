# outputs.tf in eks-cluster directory

output "cluster_endpoint" {
    description = "EKS cluster endpoint"
    value       = module.eks.cluster_endpoint
}

output "cluster_name" {
    description = "EKS cluster name"
    value       = module.eks.cluster_name
}

output "alb_dns_name" {
    description = "The DNS name of the Application Load Balancer"
    value       = aws_lb.alb.dns_name
} 