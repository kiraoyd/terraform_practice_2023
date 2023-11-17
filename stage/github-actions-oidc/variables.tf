#need a name for the aws_iam_role
variable "name" {
  description = "The name used to namespace all the resources created by the github-actions-oidc module"
  type = string
  default = "github-actions-oidc-kirak"
}