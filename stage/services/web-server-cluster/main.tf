#Configure the providers we will use

#terraform {
#  # Reminder this is partial config, must use terraform init -backend-config=backend.hcl (just init)
#  backend "s3" {
#    key = "stage/services/webserver-cluster/terraform.tfstate"
#  }
#}
#aws provider, deployed in the us-east-2 region
provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "example"{
  ami = "ami-0fb653ca2d3203ac1" #amazon machine image
  instance_type = "t2.micro"  #type of EC2 instance to run, this one has 1 virtual CPU, 1 GB of memory and is part of AWS free Tier
  vpc_security_group_ids = [aws_security_group.instance.id] #This expression references the resource aws_security_group
  tags = {
    Name = "terraform-example"
  }
  #<<-EOF and EOF wrap multiline strings without having to inser newline characters
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
  #This tells terraform to terminate the original instance and launch a new one
  user_data_replace_on_change = true
}

#Set up a security group so AWS will allow incoming and outgoing traffic from an EC2 instance
resource "aws_security_group" "instance"{
  name = "terraform-example-instance"

  ingress {
    #use the variable instead of hardcoding!
    from_port=var.server_port
    to_port=var.server_port
    #from_port = 8080
    #to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#------DEPLOYING A CLUSTER OF WEB SERVERS--------
#ASG - Auto Scaling Group (launches clusters, monitors their health, replaces failed EC2 instances, etc)

#Established how to configure each EC2 instance in the ASG
resource "aws_launch_configuration" "example" {
  image_id = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  lifecycle{
    create_before_destroy = true
  }
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
}

#Creates the ASG itself
resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  #below is where we tell our ASG to use the default VPC subnets we want it to use
  vpc_zone_identifier = data.aws_subnets.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn] #this target_group resource configured below
  health_check_type = "ELB" #level of health_check to run

  min_size = 2
  max_size = 10
  tag{
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}


#------DEPLOYING A LOAD BALANCER--------
#Distribute trafffic across all our servers
#The load balancers IP address will be the only one end users need to know to access ALL the servers

#Create the ALB (Application Load Balancer) resource:
resource "aws_lb" "example" {
  name = "terraform-asg-example"
  load_balancer_type= "application"
  #the load balancer needs to use all the subnets in our default VPC
  subnets = data.aws_subnets.default.ids #here is a reference to our aws_subnets datasource
  security_groups = [aws_security_group.alb.id] #This resource gets defined below
}

#Define the ALB Listener, to listen on a specific port and protocol
resource "aws_lb_listener" "http"{
  load_balancer_arn = aws_lb.example.arn
  port = 80
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

#Set up a Security Resource for the alb resource (a firewall basically)
#By default ALL AWS resources don't allow incoming or outgoing traffic
resource "aws_security_group" "alb"{
  name = "terraform-example-alb"

  #Allow inbound HTTP requests on port 80, allowing outside access to the load balancer over HTTP
  ingress{
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Allow all outbound requests on port 0, all ports, to allow the load balancer to perform health checks
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Set up the Target Group
resource "aws_lb_target_group" "asg" {
  name = "terraform-asg-example"
  port = var.server_port
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


#This allows the web server to read the outputs from the databases state file
#By adding the terraform_remote_state data source
#This data source configures the web server cluster code to read the state file from teh same S3 bucket and folder where the database stores its state
#the data we get back here is read only
#data "terraform_remote_state" "db" {
#  backend = "s3"
#  config = {
#    bucket = "example-bucket-kirak-fullcircle"
#    key    = "stage/data-stores/postgres/terraform.tfstate"
#    region = "us-west-2"
#  }
#}