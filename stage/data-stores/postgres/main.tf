provider "aws" {
  region = "us-east-2"
}



#---AWS SECRETS------
#gets the secret, and allows us to use 'creds' to access attributes
data "aws_secretsmanager_secret_version" "creds"{
  secret_id = "db-creds" #The name of the secret as stored in AWS secrets manager
}

locals {
  #Makes it easy to access the specific pieces of the secret later in the code
  #Now if we want a specific piece of the secret, we can get to it with the '.' operator: db_creds.username for example
  db_creds = jsoncode(
    #The datasource defined below
    data.aws_secretsmanager_secret_version.creds.secret_string #gets the secret string from the creds data source
  )
}

#This allows us to get the ARN (db url) from AWS's postgres
#Using this datasource gives us access to the metadata for the secret
data "aws_secretsmanager_secret" "db_creds" {
  name = "db-creds" #As stored in the AWS secrets manager
}

#Yet another version of the AWS secrets manager secret, but this one uses info grabbed by the data sources created earlier
#This gets in the db creds stored in the AWS secretes, grabs the latest version of the secrets by default
#We name the version for easy identification, can be used if we have multiple secrets
resource "aws_secretsmanager_secret_version" "db_creds_current" {
  secret_id = data.aws_secretsmanager_secret.db_creds.id
  #this sets up all our secretes in a JSON string so we can grab them easily
  secret_string = <<EOF
{
  "username":"${local.db_creds.username}",
  "password": "${local.db_creds.password}",
  "address": "${module.postgres.address}",
  "port" :"${module.postgres.port}"
}
EOF
}

#Make the postgres module here, so we can pass in the creds from the secrets to the module
#This replaces the module from the book (that had us pass in the name and password as vars)
module "postgres" {
  source = "../../../modules/data-stores/postgres"
  db_name = var.db_name
  db_password = local.db_creds.password
  db_username = local.db_creds.username
}


terraform {
  # Reminder this is partial config, must run terraform init -backend-config=../../../global/config/backend.hcl  in postgres
  #
  backend "s3" {
    key = "stage/data-stores/postgres/terraform.tfstate"
  }
}