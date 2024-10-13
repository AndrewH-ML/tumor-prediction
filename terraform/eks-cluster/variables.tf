# variables.tf in eks-cluster directory 

variable "aws_region" {
  default = "us-west-1"
}

# VPC AND SUBNETS

variable "vpc_cidr" {
  default = "192.168.0.0/16"
}

variable "public_subnets" {
  default = ["192.168.1.0/24", "192.168.2.0/24"]
}

variable "private_subnets" {
  default = ["192.168.3.0/24", "192.168.4.0/24"]
}

variable "availability_zones" {
  default = ["us-west-1a", "us-west-1c"]
}

variable "cluster_name" {
    default = "tumor-prediction-cluster"
}

# NODE GROUP VARIABLES

variable "instance_type" {
    default = "t3.micro"
}

variable "desired_capacity" {
    default = 2
}

variable "min_size" {
    default = 1
}

variable "max_size" {
    default = 3
}

variable "kubernetes_version" {
  default = "1.29"
}
