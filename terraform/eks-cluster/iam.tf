# iam.tf in terraform/eks-cluster/

# EKS CLUSTER ROLE 

resource "aws_iam_role" "eks_cluster_role" {
    name = "${var.cluster_name}-cluster-role"
    assume_role_policy  = data.aws_iam_policy_document.eks_cluster_assume_role.json
}

data "aws_iam_policy_document" "eks_cluster_assume_role" {
    statement {
        effect = "Allow"
        principals {
            type     = "Service"
            identifiers = ["eks.amazonaws.com"]
        }
        actions = ["sts:AssumeRole"]
        
    }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
    role       = aws_iam_role.eks_cluster_role.name
}

# EKS NODE GROUP ROLE 

resource "aws_iam_role" "eks_node_role" {
    name = "${var.cluster_name}-node-role"
    assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json
}

data "aws_iam_policy_document" "eks_node_assume_role" {
    statement {
        effect = "Allow"
        principals {
            type    = "Service" 
            identifiers = ["ec2.amazonaws.com"]
        }
        actions = ["sts:AssumeRole"]
    }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}
