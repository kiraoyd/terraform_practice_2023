
#Adding the K8s provider, we will use this to make the deployment and service resourcea
terraform {
  required_version = ">= 1.0.0, < 2.0.0"
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

#local variables
locals {
  pod_labels = {
    app= var.name
  }
}

#Deployment Resource
resource "kubernetes_deployment" "app" {
  #metadata can be used to identify and target this object in API calls
  metadata {
    name = var.name
  }

  #the spec block contains the rest of the configuration
  spec {
    replicas = var.replicas #number of docker image replicas to make
    #the template block defines the template for the pod of containers (which containers to run, the ports to use, ENV vars, etc)
    template {
      #metadata block for the pod template
      metadata {
        labels = local.pod_labels
      }
      spec {
        #The container block defines one or more containers that will be run in this Pod
        #TODO what will it look like if there are more than one container in here?
        container {
          name  = var.name #container name
          image = var.image #docker image to run in the container

          #ports to expose in this container
          port {
            container_port = var.container_port
            #assumes just one, but could be multiple ports
          }
          #ENV vars to expose to the container, this example uses a dynamic block
          dynamic "env" {
            for_each = var.environment_variables #iterates over the env.._var... input variables map
            #content is what's inside each env..._var.. we iterate over, see chapter 5
            content {
              name  = env.key
              value = env.value
            }
          }
        }
      }
    }

    #This selector block tells the kubernetes deployment what to target
    selector {
      match_labels = local.pod_labels
      #set to pod_labels so it manages deployments for the pod template we defined directly above
      #It's possible to define a deployment for pods defined seperately, so it's important to always specify a selector target
    }
  }
}


#Set up the kubernetes service
resource "kubernetes_service" "app" {
  #metadata identifies and targets this object in the API calls
  metadata {
    name = var.name
  }

  #configurations for the service
  spec {
    type = "LoadBalancer" #the type varies with the k8s configuration
    #what ports the load balancer should listen on
    port {
      port = 80 #default port for Http
      target_port = var.container_port
      protocol = "TCP"
    }
    #need to specify what this service should be targeting! Which pod?
    selector = local.pod_labels
  }
}