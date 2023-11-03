provider "aws" {
  region = "us-east-2"
}

#AWS database resource for postgres
resource "aws_db_instance" "mem-overflow" {
  identifier_prefix   = "kirak-mem-overflow"
  engine              = "postgres"
  allocated_storage   = 10 #in GB
  instance_class      = "db.t3.micro" #specifies CPU, memory for this instance
  skip_final_snapshot = true #enabled since this is just example code
  db_name             = "mem_overflow"
  # How should we set the username and password?
  #This is where we want to use terraform_remote_state
  username = var.db_username
  password = var.db_password
}

#configure this module to store its state in teh S3 bucket
terraform {
  # Reminder this is partial config, must use terraform init -backend-config=backend.hcl (just init)
  #
  backend "s3" {
    bucket = "example-bucket-kirak-fullcircle"
    key = "stage/data-stores/postgres/terraform.tfstate"
    #key = "live/data-stores/postgres/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "terraform-up-and-running-lock"
    encrypt = true
  }
}