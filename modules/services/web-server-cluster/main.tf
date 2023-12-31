#Configure the providers we will use

#aws provider, deployed in the us-east-2 region
provider "aws" {
  region = "us-east-2"
}

locals {
  http_port = 80
  any_port = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips = ["0.0.0.0/0"]
}

#GET SUBNET ID's into the ASG, specifying which VPC subnets the EC2 instances should be deployed to
#Datasouce: read only information fetched from the provider (AWS) each time we run terraform

#sets up the aws_vpc data source to look up the data for the default VPC (Virtual Private Cloud)
data "aws_vpc" "default" {
  default = true
}

#Allows us to look up all the subnets within the default VPC defined in the aws_vpc datasource
data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id] #grabs the id from the aws_vpc data source
  }
  # Add this filter to select only the subnets in the us-west-2[a-c] Availability Zone because 2d doesn't support t2.micro
  #  filter {
  #    name = "availability-zone"
  #    values = ["us-west-2a", "us-west-2b", "us-west-2c"]
  #  }
}


#Set up a security group so AWS will allow incoming and outgoing traffic from an EC2 instance
resource "aws_security_group" "instance"{
  name = "${var.cluster_name}-instance"

  #We've now broken this in-line block out into it's own resource below: allow_http_inbound_instance
#  ingress {
#    #use the variable instead of hardcoding!
#    from_port=local.http_port
#    to_port=local.http_port
#    protocol = local.tcp_protocol
#    cidr_blocks = local.all_ips
#  }
}
resource "aws_security_group_rule" "allow_http_inbound_instance"{
  type ="ingress"
  security_group_id = aws_security_group.instance.id

  from_port=local.http_port
  to_port=local.http_port
  protocol = local.tcp_protocol
  cidr_blocks = local.all_ips
}

#------DEPLOYING A CLUSTER OF WEB SERVERS--------
#ASG - Auto Scaling Group (launches clusters, monitors their health, replaces failed EC2 instances, etc)

#Established how to configure each EC2 instance in the ASG
resource "aws_launch_configuration" "example" {
  image_id = "ami-0fb653ca2d3203ac1"
  #image_id = "ami-03f65b8614a860c29"
  instance_type = var.instance_type
  security_groups = [aws_security_group.instance.id]
  #now instead of including the entire bash script here in the config, we jus make a call to the templatefile() function we wrote in user-data.sh:
  #use ${path.module} because you need a path relative to the module itself
  user_data = templatefile("${path.module}/user-data.sh", {
    server_port = local.http_port
    db_address = data.terraform_remote_state.db.outputs.address
    db_port = data.terraform_remote_state.db.outputs.port
  })
  lifecycle{
    create_before_destroy = true
  }
}



#Creates the ASG itself
resource "aws_autoscaling_group" "example-asg" {
  launch_configuration = aws_launch_configuration.example.name
  #below is where we tell our ASG to use the default VPC subnets we want it to use
  vpc_zone_identifier = data.aws_subnets.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn] #this target_group resource configured below
  health_check_type = "ELB" #level of health_check to run

  min_size = var.min_size
  max_size = var.max_size
  tag{
    key = "Name"
    value = "${var.cluster_name}-asg"
    propagate_at_launch = true
  }
}


#------DEPLOYING A LOAD BALANCER--------
#Distribute trafffic across all our servers
#The load balancers IP address will be the only one end users need to know to access ALL the servers

#Set up a Security Resource for the alb resource (a firewall basically)
#By default ALL AWS resources don't allow incoming or outgoing traffic
resource "aws_security_group" "alb" {
  name = "${var.cluster_name}alb"

  #Allow inbound HTTP requests on port 80, allowing outside access to the load balancer over HTTP
  #Now broken out into seperate resources below: allow_http_inbound_alb and allow_all_outbound_alb
#  ingress {
#    from_port   = local.http_port
#    to_port     = local.http_port
#    protocol    = local.tcp_protocol
#    cidr_blocks = local.all_ips
#  }
#
#  egress {
#    from_port   = local.any_port
#    to_port     = local.any_port
#    protocol    = local.any_protocol
#    cidr_blocks = local.all_ips
#  }
}

resource "aws_security_group_rule" "allow_http_inbound_alb"{
  type ="ingress"
  security_group_id = aws_security_group.alb.id

  from_port=local.http_port
  to_port=local.http_port
  protocol = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound_alb"{
  type ="egress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}


#Create the ALB (Application Load Balancer) resource:
resource "aws_lb" "example-lb" {
  name = "${var.cluster_name}-asg"
  load_balancer_type= "application"
  #the load balancer needs to use all the subnets in our default VPC
  subnets = data.aws_subnets.default.ids #here is a reference to our aws_subnets datasource
  security_groups = [aws_security_group.alb.id] #This resource gets defined below
}

#Set up the Target Group
resource "aws_lb_target_group" "asg" {
  name = "example-asg"
  port = local.http_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP" #the form of the health check request
    matcher = "200" #the expected response from the HTTP request
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}


#Define the ALB Listener, to listen on a specific port and protocol
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example-lb.arn
  port = local.http_port
  protocol = "HTTP"

  #set up the default to return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}



#Next up: write the listener_rules that match each request to a path
#Acts like a router, grabs incoming requests and sends them to match specific paths

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    #matches ANY path to the target group containing our ASG
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}


#To delete the AWS resources, run terraform destroy


#This allows the web server to read the outputs from the databases state file thats shared in S3
#By adding the terraform_remote_state data source
#This data source configures the web server cluster code to read the state file from teh same S3 bucket and folder where the database stores its state
#the data we get back here is read only
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key #the location of the state file for the db
    region = "us-east-2"
  }
}

