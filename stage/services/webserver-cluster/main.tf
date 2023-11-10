provider "aws" {
  region = "us-east-2"
}

module "web_server_cluster"{
  source="../../../modules/services/web-server-cluster"

  #set the values for the modules input variables here, specific to this environment (stage), they will be different for production
  cluster_name = "terraform-example"
  db_remote_state_bucket = "example-bucket-kirak-fullcircle"
  db_remote_state_key="stage/data-stores/postgres/terraform.tfstate"

  instance_type = "t2.micro"
  min_size = 2
  max_size = 2
}

resource "aws_security_group_rule" "allow_testing_inbound"{
  type = "ingress"
  security_group_id = module.web_server_cluster.alb_security_group_id #output variable of module

  from_port = 12345
  to_port = 12345
  protocol = "tcp"
  cidr_blocks=["0.0.0.0/0"]
}

terraform {
  # Reminder this is partial config, must use terraform init -backend-config=../../../global/config/backend.hcl  in web-server-cluster
  backend "s3" {
    key="stage/services/webserver-cluster.tfstate"
  }
}