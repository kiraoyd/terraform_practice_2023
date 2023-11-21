#Resources to manage github workflows for credentials
#Using OICD (Open ID Connect) to establish a trusted link between the CI system in github and our AWS cloud provider
#Allowing us to authenticate to those providers without having to manage any credentials manually
#------Specifically everything here lets github authenticate itself to our AWS account------#
terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

# Create an IAM OIDC identity provider that trusts GitHub
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com" #github actions OIDC provider
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    data.tls_certificate.github.certificates[0].sha1_fingerprint
  ]
}
# Fetch GitHub's OIDC thumbprint
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

#Create an IAM role with EC2 permissions attached
#You don't NEED this persay, since we are using root
#IF we need to make another account
resource "aws_iam_role" "instance" {
  name_prefix = var.name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

#allows the IAM role to be assumed by specific github repos
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect = "Allow"

    principals {
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
      type = "Federated"
    }

    condition {
      test = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      #We will define the repos and branches in the variable: allowed_repos_branches
      values = [
        for a in var.allowed_repos_branches :
        "repo:${a["org"]}/${a["repo"]}:ref:refs/heads/${a["branch"]}"
      ]
    }
  }
}

#attach policy to the IAM role
resource "aws_iam_role_policy" "example" {
  role = aws_iam_role.instance.id
  policy = data.aws_iam_policy_document.ec2_admin_permissions.json
}

#EC2 Permissions need to be added to the IAM role (default is none)
data "aws_iam_policy_document" "ec2_admin_permissions" {
  statement {
    effect = "Allow"
    actions = ["ec2:*"]
    resources = ["*"]
  }
}



#----------------------------------------------------------#