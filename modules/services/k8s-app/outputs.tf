locals {
  status = kubernetes_service.app.status #a k8s service attribute that returns the latest status of the service
}

#the status returned by the attribute is burried in a complicated nested object:
#[
#  {
#   load_balancer = [
#     {
#       ingress = [
#         {
#           hostname = "<HOSTNAME>"
#         }
#       ]
#     }
#    ]
#  }
#]
#So once we have that object, we need to index in in a complex way:

output "service_endpoint" {
  #we use try just in case the status object comes back in a slightly different format
  #the first arf to try is on success, and the second will be on failure
  value = try(
    "http://${local.status[0]["load_balancer"][0]["ingress"][0]["hostname"]}",
    "(error parsing hostname from status)"
  )
  description = "The K8S Service endpoint"
}