#testing kubernetes using the book example on page 261


#adding this provider will make this module deploy into our local kubernetes cluster
#This tells the kubernetes provider to authenticate to your local kubernetes cluster by using the
#docker-desktop context from your kubectl config
provider "kubernetes" {
  config_path = "~/.kube/config"
  config_context = "docker-desktop"
}

module "simple-webapp" {
  source = "../../modules/services/k8s-app" #links to the kubernetes deployment and service we created
  name = "simple-webapp" #name of the kubernetes objects (based on their metadata)
  image = "training/webapp" #simple docker image
  replicas = 2 #two container replicas
  container_port = 5000 #exposed port

  #set this ENV to some value so it will replace the "world" word in "hello world"
  environment_variables = {
          PROVIDER = ", is it me you're looking for?"
  }
}

