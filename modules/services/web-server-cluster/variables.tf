#Don't need the server port as a variable, as it can be stored in the modules locals now
#LIES! The .sh file needs it!
variable "server_port" {
  description = "Port the server uses for HTTP requests"
  type        = number
  default     = 8080
}

variable "cluster_name" {
  description ="The name of the S3 bucket for the cluster resources."
  type=string
}

variable "db_remote_state_bucket" {
  description="The name of the S3 bucket for the database's remote state"
  type = string
}

variable "db_remote_state_key" {
  description="the path for the database's remote state in S3"
  type = string
}

variable "instance_type" {
  description="The type of EC2 instances to run (e.g. t2.micro vs a larger one)"
  type = string
}

variable "min_size" {
  description="The minimum number of EC2 instances in the ASG"
  type = number
}

variable "max_size" {
  description="the maximum number of EC2 instances in the ASG"
  type = number
}
