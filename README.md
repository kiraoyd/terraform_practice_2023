# Implementing the examples from the Terraform book

# Below is a record of important steps to be able to write and run these examples:

When opening a new terminal, always run:
```
 export AWS_ACCESS_KEY_ID=(your access key id)
 export AWS_SECRET_ACCESS_KEY=(your secret access key)
```

or you won't be able to connect to AWS.

To see what changes will be made run:

```terraform plan```

```terraform init``` can be run as many times as you'd like.

After running ```apply```, if an Error regarding the creation of a specific resource appears, it is relevant only to THAT resource.
Other resources changed or created in the plan may be created without error, independent of this error occuring.


To spin up from scratch:

Terraform init followed by apply on all folders with main.tf in them. 
In the s3 one, if you don't already have a bucket made, comment out the terraform config part before running the initial init.
Do it in this order:
1. s3 (your bucket, also referred to as our 'backend')
2. stage/data, and prod/data (your database)
3. stage/web, and prod/web (your web server cluster)

To delete everything off the AWS console, run terraform destroy.

In this order:
- web server
- Stage data-stores
- global s3

- **Don't actually delete the s3 bucket! Just delete everything inside it.**

Sometimes things dangle, if that's the case manually get rid of them in the AWS console.
EXCEPT the S3 bucket itself, just leave that. Think of it like a shared hard disk.

## Setting up an AWS postgres Database
Make a new folder in your /stage/data-stores that's for postgres.
Setup main.tf, outputs.tf and variables.tf as usual.
Follow the resource setup for the database in the main.tf 
The output variables in outputs.tf are there to practice grabbing the values in a different resource
The terraform backend config in main.tf allows the database module to store its state in the S3 bucket, which we need to be able to grab the output variables values from a DIFFERENT module

We can pass in the username and password for our database through the ENV by setting them on the command line:
```export TF_VAR_db_username="(YOUR_DB_USERNAME)"``` -> fullcircle
```export TF_VAR_db_password="(YOUR_DB_PASSWORD)"``` -> example1234

Once all this is done, in the /stage/data-stores/postgres folder, run terraform init, then terraform apply to create the database on AWS.

# Troubleshooting the dreaded error:

Initializing the backend...
╷
│ Error: Backend configuration changed
│
│ A change in the backend configuration has been detected, which may require migrating existing state.
│
│ If you wish to attempt automatic migration of the state, use "terraform init -migrate-state".
│ If you wish to store the current configuration with no changes to the state, use "terraform init -reconfigure".
╵

kirak@DESKTOP-LH72MJ6:~/terraform/terraform_practice_2023/global/s3$ terraform init

Initializing the backend...
Error refreshing state: state data in S3 does not have the expected content.

The checksum calculated for the state stored in S3 does not match the checksum
stored in DynamoDB.

Bucket: example-bucket-kirak-fullcircle
Key:    global/s3/terraform.tfstate
Calculated checksum:
Stored checksum:     e77b7dc06f5aa2e5c4ee008a5e550e05

This may be caused by unusually long delays in S3 processing a previous state
update. Please wait for a minute or two and try again.

If this problem persists, and neither S3 nor DynamoDB are experiencing an
outage, you may need to manually verify the remote state and remove the Digest
value stored in the DynamoDB table


### SOLUTION:


To manually remove the Digest value from the DynamoDB table associated with your Terraform state, follow these steps:

1. **Access DynamoDB**: Sign in to the AWS Management Console and navigate to the AWS DynamoDB service.

2. **Select Your Table**: In the DynamoDB dashboard, select the DynamoDB table used for storing Terraform state information. This table should be defined in your Terraform remote state configuration.

3. **View Table Items**: In the table details, navigate to the "Items" tab. Here, you will see a list of items (entries) in the table.

4. **Identify the Item**: Look for the specific item related to your Terraform state. The item you need to edit will typically have a key with the name of your Terraform workspace or a unique identifier associated with your state.
If you have items that don't look like they correspond with the names in your aws_dynamo_db table resource, you can manually delete them from your aws_console after deleting the digest value.

5. **Edit the Item**: Select the item, and in the item details, locate the Digest value that's causing the checksum mismatch. This Digest value is what you need to remove.

6. **Delete the Digest Value**: Delete the Digest value from the item. You can usually do this by selecting the Digest value and deleting it from the item's attributes.

7. **Save Changes**: After removing the Digest value, save your changes to the DynamoDB table.

8. **Reconfigure Terraform**: Update your Terraform configuration to ensure it points to the correct DynamoDB table. This may involve editing your `backend` configuration in your Terraform files.

9. **Reinitialize and Apply**: After making these changes, reinitialize your Terraform workspace:

   ```bash
   terraform init
   ```

   Then, try applying your configuration again:

   ```bash
   terraform apply
   ```

By removing the Digest value from the DynamoDB table, you should resolve the checksum mismatch issue and be able to work with your Terraform state as expected.

Please be extremely cautious when making changes in DynamoDB, and ensure that you are working with the correct table and item to avoid unintended data loss. Always back up your state and data before making changes.


# Nuking Everything

Run ```terraform destroy``` in the directories in this order:
1. ```stage/services/web-server-cluster```
2. ```stage/data-stores/postgres```
3. ```global/s3```

Delete all these state files manually from each of those three directories:

```current.tfstate```
```terrafrom.tfstate```
```terraform.tfstate.backup```

Delete the .terraform folder in each of the three directories.