#need a name for the aws_iam_role
variable "name" {
  description = "The name used to namespace all the resources created by the github-actions-oidc module"
  type = string
  default = "github-actions-oidc-kirak"
}

#We set these values in the terraform.tfvars file (works like a .env file)
variable "allowed_repos_branches" {
  description = "GitHub repos/branches allowed to assume the IAM role."
  type = list(object({
    org = string
    repo = string
    branch = string
  }))
  # Example:
  # allowed_repos_branches = [
  # {
  # org = "brikis98"
  # repo = "terraform-up-and-running-code"
  # branch = "main"
  # }
  # ]
}