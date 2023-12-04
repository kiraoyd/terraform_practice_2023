#Setting up an example deployment of the training/webapp Docker image to the EKS clusterwe made in modules/services/eks-cluster
#TODO we don't need kubernetes at all anymore, but will leave it around for reference
provider "aws" {
  region = "us-east-2"
}

#This is making a new instance of the eks_cluster module we defined in modules
module "eks_cluster" {
  #pass in all the values for this modules input vars
  source         = "../../../modules/services/eks-cluster"
  name           = "example-eks-cluster"
  min_size       = 1
  max_size       = 2
  desired_size   = 1
  # Due to the way EKS works with ENIs, t3.small is the smallest
  # instance type that can be used for worker nodes. If you try
  # something smaller like t2.micro, which only has 4 ENIs,
  # they'll all be used up by system services (e.g., kube-proxy)
  # and you won't be able to deploy your own Pods.
  instance_types = ["t3.small"]
}

#Configure the kubernetes provider to authenticate to EKS cluster as oposed to our local cluster on Docker Desktop
#Notice that this requires a bit more config than just letting it authenticate to our local Docker Desktop cluster
provider "kubernetes" {
  host = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(
    module.eks_cluster.cluster_certificate_authority[0].data
  )
  token = data.aws_eks_cluster_auth.cluster.token
}
#This data source is needed for the above authorization
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.cluster_name
}


#This is the SAME module deployment of the webapp we set up in modules/services/k8s-app
module "tuber_trader" {
  source                = "../../../modules/services/k8s-app"
  name                  = "tuber-trader"
  image                 = "training/webapp" #THIS WILL CHANGE LATER TO OUR IMAGE!
  replicas              = 2
  container_port        = 5000
  environment_variables = {
    PROVIDER = "Terraform"
  }
  # Only deploy the app after the cluster has been deployed
  depends_on = [module.eks_cluster] #But here we need to ensure we don't deploy the app until the cluster itself is ready
}
