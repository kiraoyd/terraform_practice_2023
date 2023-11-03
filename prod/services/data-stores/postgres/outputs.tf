
#These return the dbs address and port
output "address" {
  value       = module.postgres.address #output variable for the module
  description = "Connect to the database at this endpoint"
}

output "port" {
  value       = module.postgres.port #ouput variable for the module
  description = "The port the database is listening on"
}

#to read any of these output variables from a different module that has the terraform_remote_state datasource set up:
#data.terraform_remote_state.<NAME_YOU_GAVE_THE_TRS>.outputs.<NAME_OF_OUTPUT_VARIABLE>
#example: data.terraform_remote_state.db.outputs.port