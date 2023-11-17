#Resources to manage github workflows for credentials
#Using OICD (Open ID Connect) to establish a trusted link between the CI system in github and our AWS cloud provider
#Allowing us to authenticate to those providers without having to manage any credentials manually

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
resouorce "aws_iam_role" "instance" {
  name_prefix = var.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}