output "cluster_arn" {
  value       = module.eks_cluster.cluster_arn
  description = "ARN of the EKS cluster"
}

output "cluster_endpoint" {
  value       = module.eks_cluster.cluster_endpoint
  description = "Endpoint of the EKS cluster"
}

output "service_endpoint" {
  value       = module.tuber_trader.service_endpoint
  description = "The K8S Service endpoint"
}