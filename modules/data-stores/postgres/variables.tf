
#when it's time to pass via ENV, on the command line:
#$ export TF_VAR_db_username="(YOUR_DB_USERNAME)"
#$ export TF_VAR_db_password="(YOUR_DB_PASSWORD)"

#no defaults for these secret variables!
variable "db_username" {
  #We'd pass in the actual decription using ENV variables, to bring in securely stored username from some password mamanger
  description = "The username for the database"
  type        = string
  sensitive   = true #indicating a secret stored!
}

variable "db_password" {
  #We'd pass in the actual decription using ENV variables, to bring in securely stored password from some password mamanger
  description = "The password for the database"
  type        = string
  sensitive   = true #indicating a secret stored!
}

variable "db_name" {
  description = "The name of the database"
  type = string
  sensitive = true
}