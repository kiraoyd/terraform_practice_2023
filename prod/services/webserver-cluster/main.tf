provider "aws" {
  region = "us-east-2"
}

module "web_server_cluster"{
  source="../../../modules/services/web-server-cluster"

  #set the values for the modules input variables here, specific to this environment (stage), they will be different for production
  cluster_name = "terraform-example"
  db_remote_state_bucket = "example-bucket-kirak-fullcircle"
  db_remote_state_key="prod/data-stores/postgres/terraform.tfstate"

  instance_type = "t2.micro"
  min_size = 2
  max_size = 10
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  scheduled_action_name="scale-out-during-business-hours"
  min_size=2
  max_size = 10
  desired_capacity = 10
  recurrence = "0 9 * * *" #cron syntax for 9am, every day

  autoscaling_group_name = module.web_server_cluster.asg_name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name="scale-in-at-night"
  min_size=2
  max_size = 10
  desired_capacity = 2
  recurrence = "0 17 * * *" #cron syntax for 5pm, every day

  autoscaling_group_name = module.web_server_cluster.asg_name
}


terraform {
  # Reminder this is partial config, must use terraform init -backend-config=../../../global/config/backend.hcl  in web-server-cluster
  backend "s3" {
    key="prod/services/webserver-cluster.tfstate"
  }
}