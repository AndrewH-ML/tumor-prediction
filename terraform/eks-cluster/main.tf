# main.tf in eks-cluster directory

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

resource "aws_subnet" "public" {
    count               = 2
    vpc_id              = aws_vpc.main.id
    cidr_block          = var.public_subnets[count.index]
    availability_zone   = var.availability_zones[count.index]
    map_public_ip_on_launch = true 

    tags = {
        Name = "${var.cluster_name}-public-${count.index}"
    }
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "${var.cluster_name}-public-rt"
    }
}

resource "aws_route" "public_internet_access" {
    route_table_id      = aws_route_table.public.id 
    destination_cidr_block   = "0.0.0.0/0"
    gateway_id              = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
    count           = 2
    subnet_id       = aws_subnet.public[count.index].id
    route_table_id  = aws_route_table.public.id
}
                                                                
# PRIVATE SUBNETS

resource "aws_subnet" "private" {
    count              = 2 
    vpc_id             = aws_vpc.main.id
    cidr_block         = var.private_subnets[count.index]
    availability_zone  = var.availability_zones[count.index]

    tags = {
        Name = "${var.cluster_name}-private-${count.index}"
    }
}

resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat.id
    subnet_id     = aws_subnet.public[0].id

    tags = {
        Name = "${var.cluster_name}-nat"
    }
}

resource "aws_eip" "nat" {
    domain = "vpc"
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id
    
    tags   = {
        Name = "${var.cluster_name}-private-rt"
    }
}

resource "aws_route" "private_internet_access" {
    route_table_id          = aws_route_table.private.id 
    destination_cidr_block  = "0.0.0.0/0"
    nat_gateway_id          = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private" {
    count           = 2
    subnet_id       = aws_subnet.private[count.index].id
    route_table_id  = aws_route_table.private.id
}

# IAM Role FOR KUBECTL
/*
resource "aws_iam_role" "eks_admin_role" {
    name = "${var.cluster_name}-admin-role"
    assume_role_policy = data.aws_iam_policy_document.eks_admin_assume_role_policy.json
}

data "aws_iam_policy_document" "eks_admin_assume_role_policy" {
    statement {
        effect = "Allows"
        principals {
            type = "Service:
            identifiers = ["eks.amazonaws.com"]
        }
        actions = ["sts:AssumeRole"]
    }
}

resource "aws_iam_role_policy_attachment" "eks_admin_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
}
*/
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

provider "aws" {
    region = var.aws_region
}

resource "aws_ecr_repository" "tumor_prediction_repo" {
    name = "tumor-prediction-repo"

}

# CONFIGURE SECURITY GROUPS

# EKS CLUSTER SECURITY GROUP
resource "aws_security_group" "eks_cluster_sg" {
    name = "cluster_security"
    description = "security group for cluster"
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "${var.cluster_name}-eks-cluster-sg"
    }

}

# Allow inbound HTTPS (port 443) traffic from private subnets
resource "aws_vpc_security_group_ingress_rule" "allow_worker_traffic_ipv4" {
    count             = length(var.private_subnets)
    security_group_id = aws_security_group.eks_cluster_sg.id
    cidr_ipv4         = var.private_subnets[count.index]
    from_port         = 443
    ip_protocol       = "tcp"
    to_port           = 443
}

# Allow all outbound traffic (IPv4) from the EKS cluster to any destination
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
    security_group_id = aws_security_group.eks_cluster_sg.id
    cidr_ipv4         = "0.0.0.0/0"
    ip_protocol       = "-1"  
}
    

# WORKER NODE SECURITY GROUP
resource "aws_security_group" "worker_sg" {
    name = "worker_node_security"
    description = "security group for worker nodes"
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "${var.cluster_name}-worker-sg"
    }
}

# Allow HTTPS traffic from EKS control plane to worker nodes
resource "aws_vpc_security_group_ingress_rule" "worker_https_ingress" {
    security_group_id            = aws_security_group.worker_sg.id
    referenced_security_group_id = aws_security_group.eks_cluster_sg.id  
    from_port                    = 443
    to_port                      = 443
    ip_protocol                   = "tcp"
}

# Allow all traffic between worker nodes
resource "aws_vpc_security_group_ingress_rule" "worker_internal_traffic" {
    security_group_id            = aws_security_group.worker_sg.id
    referenced_security_group_id = aws_security_group.worker_sg.id  
    from_port                    = 1024
    to_port                      = 65535
    ip_protocol                  = "tcp"  
}

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


# APPLICATION LOAD BALANCER SECURITY GROUP
resource "aws_security_group" "alb_sg" {
    name        = "alb_security"
    description = "security group for alb"
    vpc_id      = aws_vpc.main.id

    tags = {
        Name = "${var.cluster_name}-alb-sg"
    }
}

# Allow HTTP traffic on port 80 from anywhere
resource "aws_vpc_security_group_ingress_rule" "alb_http_ingress" {
    security_group_id = aws_security_group.alb_sg.id
    cidr_ipv4         = "0.0.0.0/0"
    from_port         = 80
    to_port           = 80
    ip_protocol       = "tcp"
}

# Allow HTTPS traffic on port 443 from anywhere
resource "aws_vpc_security_group_ingress_rule" "alb_https_ingress" {
    security_group_id = aws_security_group.alb_sg.id
    cidr_ipv4         = "0.0.0.0/0"
    from_port         = 443
    to_port           = 443
    ip_protocol       = "tcp"
}

# Allow all outbound traffic (IPv4)
resource "aws_vpc_security_group_egress_rule" "alb_allow_all_egress" {
    security_group_id = aws_security_group.alb_sg.id
    cidr_ipv4         = "0.0.0.0/0"
    ip_protocol       = "-1" 
}

# APPLICATION LOAD BALANCER RESOURCE
resource "aws_lb" "alb" {
    name               = "${var.cluster_name}-alb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.alb_sg.id]
    subnets            = aws_subnet.public[*].id

    enable_deletion_protection = false

    tags = {
        Name = "${var.cluster_name}-alb"
    }
}

resource "aws_lb_listener" "http" {
    load_balancer_arn   = aws_lb.alb.arn
    port                = "80"
    protocol            = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.flask_tg.arn
    }  

}

/* resource "aws_lb_listener" "https" {
    load_balancer_arn = aws_lb.alb.arn
    port              = "443"
    protocol          = "HTTPS"
    ssl_policy        = "ELBSecurityPolicy-2016-08"
    certificate_arn   = aws_acm_certificate.example_cert.arn

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.backend_tg.arn
    }

}
*/
resource "aws_lb_target_group" "flask_tg" {
  name     = "${var.cluster_name}-tg"
  port     = 30080             
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.cluster_name}-tg"
  }
}

# create target group attachment

data "aws_instances" "worker_nodes" {
    filter {
        name = "tag:Name"
        values = ["tumor-prediction-nodes"]
    }
}

resource "aws_lb_target_group_attachment" "flask_tg_attachment" {
    count = length(data.aws_instances.worker_nodes.ids)
    target_group_arn = aws_lb_target_group.flask_tg.arn
    target_id = element(data.aws_instances.worker_nodes.ids, count.index)
    port      = 30080
}