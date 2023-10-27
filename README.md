# Implementing the examples from the Terraform book

# Below is a record of important steps to be able to write and run these examples:

When opening a new terminal, always run:
```
 export AWS_ACCESS_KEY_ID=(your access key id)
 export AWS_SECRET_ACCESS_KEY=(your secret access key)
```

To see what changes will be made run:

```terraform plan```

```terraform init``` can be run as many times as you'd like.

After running ```apply```, if an Error regarding the creation of a specific resource appears, it is relevant only to THAT resource.
Other resources changed or created in the plan may be created without error, independent of this error occuring.


To delete everything off the AWS console, run terraform destroy.

In this order:
- web server
- Stage data-stores
- global s3
- 
Sometimes things dangle, if thats the case manually get rid of them in the AWS console.


