#set up the variable to hold a port number
#At runtime you will get prompted to enter a value, since no default is specified
variable "server_port"{
  description = "The port the server will use for HTTP requests"
  type = number
  default=8080 #leaving this here saves us needing to enter it at runtime
}

variable "cluster_name" {
  description ="The name of the S3 bucket for the cluster resources."
  type=string
  default="terraform-example" #dev only
}

variable "db_remote_state_bucket" {
  description="The name of the S3 bucket for the database's remote state"
  type = string
  default="example-bucket-kirak-fullcircle"
}

variable "db_remote_state_key" {
  description="the path for the database's remote state in S3"
  type = string
  default="stage/data-stores/postgres/terraform.tfstate"
}

variable "instance_type" {
  description="The type of EC2 instances to run (e.g. t2.micro vs a larger one)"
  type = string
  default="t2.micro"
}

variable "min_size" {
  description="The minimum number of EC2 instances in the ASG"
  type = number
  default=2
}

variable "max_size" {
  description="the maximum number of EC2 instances in the ASG"
  type = number
  default=2
}