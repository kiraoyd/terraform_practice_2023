provider "aws" {
  region = "us-east-2"
}

module "webserver_cluster"{
  source="../../../modules/services/web-server-cluster"

  #set the values for the modules input variables here, specific to this environment (stage), they will be different for production
  cluster_name = "terraform-example"
  db_remote_state_bucket = "example-bucket-kirak-fullcircle"
  db_remote_state_key="stage/data-stores/postgres/terraform.tfstate"

  instance_type = "t2.micro"
  min_size = 2
  max_size = 2
}