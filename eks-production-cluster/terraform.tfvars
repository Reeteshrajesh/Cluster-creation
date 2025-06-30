region             = "ap-south-1"
cluster_name       = "prod-eks-cluster"
vpc_cidr           = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]
private_subnet_cidrs = ["10.0.128.0/20", "10.0.144.0/20", "10.0.160.0/20"]
node_instance_type = "t3.medium"
desired_capacity   = 3
