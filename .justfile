project := justfile_directory()
s3 := project + "/global/s3"
webserver := project + "/stage/services/webserver-cluster"
postgres := project + "/stage/data-stores/postgres"

#staging webserver
@web *cmd:
    cd {{webserver}} && just {{cmd}}

# global s3
@s3 *cmd:
    cd {{postgres}} && just {{cmd}}

#To use: just webserver init, just s3 apply, etc