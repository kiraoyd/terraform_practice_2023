provider "aws" {
  region = "us-east-2"
}

#The AWS secrets manager
data "aws_secretsmanager_secret_version" "creds"{
  secret_id = "db-creds"
}

#parse the AWS secrets JSON
locals {
  db_creds = jsondecode(
    data.aws_secretsmanager_secret_version.creds.secret_string
  )
}

#AWS database resource for postgres
#Per chapter 7, we can update this to include a backup database, that lives in an entirely different region
#No code to do this deployed yet, to save charges, but reference pages 230-231 in the book
resource "aws_db_instance" "mem-overflow" {
  identifier_prefix   = "kirak-mem-overflow"
  engine              = "postgres"
  allocated_storage   = 10 #in GB
  instance_class      = "db.t3.micro" #specifies CPU, memory for this instance
  skip_final_snapshot = true #enabled since this is just example code
  db_name             = var.db_name
  # How should we set the username and password?
  #This is where we want to use terraform_remote_state
  #Replace the use of the var info, with the AWS secret instead
  #username = var.db_username
  #password = var.db_password

  username = local.db_creds.username
  password = local.db_creds.password
}


