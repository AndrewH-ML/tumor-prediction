# cluster.tf in terraform/eks-cluster/

# EKS CLUSTER MODULE 

module "eks" {
    source          = "terraform-aws-modules/eks/aws"
    version         = "~> 20.0" 
    
    cluster_name    = var.cluster_name
    cluster_version = var.kubernetes_version
    vpc_id          = aws_vpc.main.id
    subnet_ids      = aws_subnet.private[*].id
    
    cluster_endpoint_private_access = true
    cluster_endpoint_public_access  = true
    enable_cluster_creator_admin_permissions = true 

    cluster_security_group_id = aws_security_group.eks_cluster_sg.id

    iam_role_arn = aws_iam_role.eks_cluster_role.arn 

    cluster_addons = {
        coredns = {
        resolve_conflicts = "OVERWRITE"
        version           = "v1.11.1-eksbuild.9"
        }
        kube-proxy = {
        resolve_conflicts = "OVERWRITE"
        version           = "v1.30.0-eksbuild.3"
        }
    }
        tags = {
            Environment = "production"
            Project     = "tumor-prediction"
        }

}


module "eks_managed_node_group" {
  source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"

  cluster_name    = module.eks.cluster_name
  instance_types  = [var.instance_type]
  desired_size    = var.desired_capacity
  min_size        = var.min_size
  max_size        = var.max_size

  subnet_ids      = aws_subnet.private[*].id
  cluster_service_cidr   = "172.20.0.0/16"

  iam_role_arn    = aws_iam_role.eks_node_role.arn

  name = "tumor-prediction-nodes"
  
  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  vpc_security_group_ids = [aws_security_group.worker_sg.id]

  tags = {
    Environment = "production"
    Project     = "tumor-prediction"
    Name        = "tumor-prediction-nodes"
  }
}


# EKS CLUSTER SECURITY GROUP
resource "aws_security_group" "eks_cluster_sg" {
    name = "cluster_security"
    description = "security group for cluster"
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "${var.cluster_name}-eks-cluster-sg"
    }

}

# CONFIGURE SECURITY GROUPS    

# WORKER NODE SECURITY GROUP
resource "aws_security_group" "worker_sg" {
    name = "worker_node_security"
    description = "security group for worker nodes"
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "${var.cluster_name}-worker-sg"
    }
}


# Allow outbound HTTPS from control plane to worker nodes
resource "aws_vpc_security_group_ingress_rule" "allow_worker_traffic_ipv4" {
    security_group_id = aws_security_group.eks_cluster_sg.id
    referenced_security_group_id = aws_security_group.worker_sg
    from_port         = 443
    to_port           = 443
    ip_protocol       = "tcp"
}



# Allow inbound HTTPS traffic from EKS control plane to worker nodes
resource "aws_vpc_security_group_ingress_rule" "worker_https_ingress" {
    security_group_id            = aws_security_group.worker_sg.id
    referenced_security_group_id = aws_security_group.eks_cluster_sg.id  
    from_port                    = 443
    to_port                      = 443
    ip_protocol                   = "tcp"
}

# Allow outbound traffic to worker nodes on port 10250
# Allow all traffic between worker nodes
resource "aws_vpc_security_group_ingress_rule" "worker_internal_traffic" {
    security_group_id            = aws_security_group.worker_sg.id
    referenced_security_group_id = aws_security_group.worker_sg.id  
    from_port                    = 1024
    to_port                      = 65535
    ip_protocol                  = "tcp"  
}

# Allows traffic from alb to worker on port 30080
resource "aws_vpc_security_group_ingress_rule" "worker_allow_alb_ingress" {
    security_group_id            = aws_security_group.worker_sg.id
    referenced_security_group_id = aws_security_group.alb_sg.id
    from_port                    = 30080
    to_port                      = 30080
    ip_protocol                  = "tcp"
}
# Allow all outbound traffic (IPv4)
resource "aws_vpc_security_group_egress_rule" "worker_allow_all_egress" {
    security_group_id = aws_security_group.worker_sg.id
    cidr_ipv4         = "0.0.0.0/0"
    ip_protocol       = "-1" 
}

