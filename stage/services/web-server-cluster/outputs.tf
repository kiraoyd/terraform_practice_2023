##Outputs the public IP for the AWS instance to the console
#output "public_ip"{
#  value = aws_instance.example.public_ip
#  description = "The public IP address of the web server"
#}
#

#the previous output variable of public_ip isn't needed anymore
#We can just directly output the DNS name of the ALB:

output "alb_dns_name"{
  value = aws_lb.example.dns_name
  description = "The domain name of the load balancer."
}
