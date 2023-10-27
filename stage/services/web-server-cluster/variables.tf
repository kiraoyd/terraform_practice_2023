#set up the variable to hold a port number
#At runtime you will get prompted to enter a value, since no default is specified
variable "server_port"{
  description = "The port the server will use for HTTP requests"
  type = number
  default=8080 #leaving this here saves us needing to enter it at runtime
}
