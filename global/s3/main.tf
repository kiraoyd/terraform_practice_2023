provider "aws" {
  region = "us-east-2"
}

#make an s3 bucket
resource "aws_s3_bucket" "terraform_state" {
  #Each bucket name must be globally unique among all AWS customers
  bucket = "example-bucket-kirak-fullcircle"

  #prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }
}

#enable versioning to see full revision history of all state files
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration{
    status= "Enabled"
  }
}

#turn on server side encryption by defaault
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#block all access explicity
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.terraform_state.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

#create dynamoDB table for locking, its one of Amazons distributed key-value stores
resource "aws_dynamodb_table" "terraform_locks" {
  name = "terraform-up-and-running-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID" #This is the primary key

  attribute {
    name = "LockID"
    type = "S"
  }
}

#IMPORANT!!!! RUN INIT (download provider code) AND APPLY (to deploy the bucket) ONCE HERE BEFORE MOVING ON!

#here we configure terraform itself to store the state in our S3 bucket
## Reminder this is partial config, must run terraform init -backend-config=../config/backend.hcl  in s3
#
terraform {
  backend "s3" {
    #name of s3 bucket to use
    #bucket = "example-bucket-kirak-fullcircle"
    #filepath within the s3 bucket where the tf state file should be written
    key = "global/s3/terraform.tfstate"
    #region where the bucket lives, should match what we set for the s3 bucket earlier
    #region = "us-east-2"

    #the table used for locking, reference the one we made earlier
    #dynamodb_table = "terraform-up-and-running-lock"
    #setting this to true ensures all state will be encrypted when stored to the s3, this is a second layer
    #encrypt = true
  }
}

#run init again here


