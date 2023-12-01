#First up, create an IAM role that can be assumed by the EKS service and give it a policy that gives it the permissions it needs


# Create an IAM role for the control plane
resource "aws_iam_role" "cluster" {
  name = "${var.name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json
}
# Allow EKS to assume the IAM role
data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}
# Attach the permissions the IAM role needs
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

#Now move on to adding the aws_vpc and aws_subnets data sources to get information about the default VPC and it's subnets
#TODO I'm not sure I fully understand VPC and subnets yet

# Since this code is only for learning, use the Default VPC and subnets.
# For real-world use cases, you should use a custom VPC and private subnets.
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


#Now we can actually create the control plane for the EKS cluster:
resource "aws_eks_cluster" "cluster" {
  name = var.name
  role_arn = aws_iam_role.cluster.arn #this is the IAM role we just made, and want the cluster to use
  version = "1.28"
  vpc_config {
    subnet_ids = data.aws_subnets.default.ids
  }
  # Ensure that IAM Role permissions are created before and deleted after
  # the EKS Cluster. Otherwise, EKS will not be able to properly delete
  # EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy
  ]
}


#Now we need to make the worker nodes
#We will be using one of three AWS types: self-managed EC2 Instances (e.g., in an ASG that you create), AWS-managed EC2
#Instances (known as a managed node group), and Fargate (serverless), specifically, the managed node group one

# Create yet another IAM role, this time for the node group
#This will be assumed by the EC2 service, seeing as the managed node group uses EC2 instances under the hood
resource "aws_iam_role" "node_group" {
  name = "${var.name}-node-group"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json
}
# Allow EC2 instances to assume the IAM role
data "aws_iam_policy_document" "node_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
# Attach the permissions the node group needs
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.node_group.name
}
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = aws_iam_role.node_group.name
}
resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role = aws_iam_role.node_group.name
}


#Finally, create the actual node group itself:
resource "aws_eks_node_group" "nodes" {
  cluster_name = aws_eks_cluster.cluster.name
  node_group_name = var.name #one of our input vars
  node_role_arn = aws_iam_role.node_group.arn #the IAM role for the node group we just made above
  subnet_ids = data.aws_subnets.default.ids #deploys to the defauly VPC
  instance_types = var.instance_types #one of our input vars
  scaling_config {
    #all of these are input vars
    min_size = var.min_size
    max_size = var.max_size
    desired_size = var.desired_size
  }
  # Ensure that IAM Role permissions are created before and deleted after
  # the EKS Node Group. Otherwise, EKS will not be able to properly
  # delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
  ]
}