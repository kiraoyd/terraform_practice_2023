##Outputs the public IP for the AWS instance to the console
#output "public_ip"{
#  value = aws_instance.example.public_ip
#  description = "The public IP address of the web server"
#}
#

#the previous output variable of public_ip isn't needed anymore
#We can just directly output the DNS name of the ALB:
#Module outputs are also directly available via module.<MODULE_NAME>.<OUTPUT_NAME>

output "alb_dns_name"{
  value = aws_lb.example-lb.dns_name
  description = "The domain name of the load balancer."
}

output "asg_name" {
  value = aws_autoscaling_group.example-asg.name
  description="The name of the autoscaling group"
}

#Allows us to set specific security group rules inside the prod/stage main.tf, using this variable
#See stage/services/web-server-cluster/main.tf at "allow_testing_inbound"
output "alb_security_group_id" {
  value = aws_security_group.alb.id
  description="The ID of the Security Group attached to te load balancer"
}