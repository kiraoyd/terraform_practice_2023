# Implementing the examples from the Terraform book

Note: for Chapter 3 branch, the s3 bucket is region US-east-2, can't change it

# Below is a record of important steps to be able to write and run these examples:

When opening a new terminal, always run:and hang on, I mi
```
 export AWS_ACCESS_KEY_ID=(your access key id)
 
 (your secret access key)
```

## Testing a Docker Container loally
1. ```docker build -t app_name .```
2. ```docker run -it --rm -p 3000:3000 app_name```

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


# Modules

We do not need to run init or apply on modules.
Those will happen automatically once we init and apply to the resources drawing on the modules.

Any terraform directory can be used as a reusable module. Key points:
1. You create a module directory at the same level as your production, stage, and global directories
2. When you want to use a module inside your prod and stage directories, 'call' it using this syntax: ```module "<name_of_module> { source = "../../../modules/services/<name_of_module_file>" }```
This will allow the code in that module to run anywhere you call the module, without the need to copy paste.
3. **Anytime you add a new module or modify the source parameter of a moduel, you have to run init!**
3. Any hardcoded names in the module need to be replaced with input variables: make a variable in varitables.tf for that module, then replace all hardcoded names with ${variable_name} in the actual resource and module code 
Basically, any name you want to be configurable or may vary depending on the environment, you want to make input variables
4. If you want, you can set specific variables right there in the module syntax call, such as ```module "webserver-cluster" { source = "filepath" min_size = 2, max_size = 2```
5. If you want to make local values in a module, create a 'locals block', for example: 
```terraform
locals { 
   http_port=80 
   any_port = 0
   all_ips=["0.0.0.0/0"]
}
``` 
Then to use any of thee within the module just specify: ```local.<NAME>```
6. you can have an outputs.tf file in your modules as well, and to access them outside the module via: ```module.<module_name>.<output_variable_name>```
7. Versioned Modules: Store youor modules in a seperate repo, then when you call the module by declaring it in production or staging, you can apply version's to the name like so:
```terraform
#in stage
module "<name> {
   source = "<repo url...>ref=v0.0.1"
}

#in prod
module "<name> {
   source = "<repo url...>ref=v0.0.2"
}
    
```

Note: In the modules, we no longer need the terraform { backend "s3"{}} block, that only has to live in the main.tf's of the folders that deploy this module.


# Order of operations for Chapter 4 Refactor:

**Set up the s3 bucket**
1. just init-migrate -> s3
2. just apply -> s3

**prep the data-store postgres for both stage and prod**
3. just init-migrate -> stage/postgres
4. just apply -> stage/postgres
5. just init-migrate -> prod/postgres
6. just apply -> prod/postgres

**Deploy the cluster from stage**
7. just init-migrate -> stage/webserver-cluster
8. just apply -> stage/webserver-cluster

We don't have to run init and apply on the prod webserver-cluster, while the stage is running

# Github actions workflow

Make sure your github access token has the right permissions to create or update workflows:

1. Logon to github
2. Settings --> Developer Settings --> Personal Access Tokens
3. Generate a new basic token with a "workflow" scope

The github-actions-oidc folder sets up AWS to authenticate github actions using the IAM role.
Now we shouldn't have to send in our AWS key and private key via the export ENV lines anymore.
I'll test this and verify before removing those instructions from this readme.

### To test github actions - AWS authentication

1. push the repo 
2. Navigate to the 'Actions' tab on github
3. check the workflows, any errors will show there

## database Creds Secrets

We can use Amazon Secrets Manager to store the username and password to our database.
We can store in plaintext via JSON.
For this example, the secret I created is:
```json
{
"username":"dbuser",
"password":"example1234",
"name":"fullcircle"
}
```
And the name I gave the AWS secret is ```db-creds```
Once stored in AWS, to get access to the secrets I can make a new datasource: "aws_secretsmanager_secret_version", parse the JSON using jsondecode() into the locals{} variables, and access them using the syntax: ```local.db_creds.username```.
NOTE: where in the terraform should this go? I'm starting by putting it in modules/postgres/main.tf

Next: Let's handle secrets being stored in our tf.state files.
Lucky for us we are using a secure backend, S3. If we were in prod, we'd want to set the IAM policu to soley grant access to the S3 bucket to a small team of trusted devs.

What about secrets in the Plan files? Secrets passed into the resources and data sources also end up here!
So we have to encrypt the plan files both in transit, and on disk. 

TODO: not sure how to ensure the plan files are encrypted...ASK CASEY

# Spinning things up as of Chapter 6:

1. global/s3 --> just init-migrate (if any changes made to the s3)
2. global/s3 --> just apply
3. stage/data-stores/postgres --> just apply
4. stage/services/webserver-cluster --> just apply
5. Destroy everything to avoid charges: ./destroy_stage.sh followed by ./destroy_s3.sh

# Next up: Chapter 7, using multiple providers

Providers are plugins for the terraform core.
Each plugin is designed to work with the platforms like AWS and azure.
Plugin code, like AWS provider stuff, lives in its own repo.
When we add a provide block like:
```
provider "aws" {
region = "us-east-2"
}
```

terraform init will auto download the provider code for us (in our webserver code)
But to have more control over providers, you want to use a required_providers block.

We can also set more configurations to our actual provider, than just region.
But what if we want to have some resources with the same provider, but a different config setup?
We need to configure multiple COPIES of the same provider. To do this, set an alias:

```
provider "aws" {
  region = "us-east-2"
  #See the AWS provider documentation for all configuration options
  alias = "region_east" #adding an alias allows us to make another copy of "aws" with different config
}
```

Now when makine a resrouce, use the alias name:
```
data "aws_region" "region_east" {
provider = aws.region_east
}

output "region_east" {
value = data.aws_region.region_east.name
description = "The name of the first region"
}
```

If you set two different regions, the AMI ID's for each instance you make per region will differ per region

Here is an example of how to make a data source that looks up AMI ID's for you:
```terraform
data "aws_ami" "ubuntu_region_1" {
   provider = aws.region_1
   most_recent = true
   owners = ["099720109477"] # Canonical
   filter {
      name = "name"
      values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
   }
}
```

USE ALIAS'S sparingly! If one region goes down, and you need to change your terraform code, apply will stop working.


# Where to pick up next time: trouble shoot github actions erroring on:

No OpenIDConnect provider found in your account for https://token.actions.githubusercontent.com

# Kubernetes

Kubernetes allows us to deploy Docker Containers at scale.
It will streamline the process of distributing the containers across multiple AWS (or other providers) servers.
Once we have kubernetes set up in our terraform infastructure, using the kubernetes deployment and service, we'll be able to host all of our websites docker containers across AWS's cloud.
Each Docker container that makes up our site, can be spun up on a different one of AWS's EC2 server instances, and kubernetes ensures they will all work together to deploy our site seamlessly.

The Control Plane in kubernetes is responsible for managing the Kubernetes cluster, the 'brains' of the operation.
It stores the clusters state, monitors the containers and coordinates actions across the cluster.
It also runs the API server liek kubectl (API you can use from the command-line) to control whats happening in the cluster.

Worker Nodes are the actual servers used to run your containers, they are entirely managed by the control plane which tells each worker node what containers it should run.
Let's see if I can get the kubernetes deployment and service code up and running.

Download kubectl:

1. Get the binary: curl -LO https://dl.k8s.io/release/v1.28.4/bin/linux/amd64/kubectl

2. Get the checksum file: curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"

2. Checksum to validate: echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

Valid binary should output: ```kubecrtl: ok```

3. Install kubectl: sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

4. Test: kubectl version --client

Update $HOME/.kube/config file to tell it which kubernetes cluser to connect to. 
Wheny ou enable Kubernetes in Docker Desktop, this gets updates automatially and all we need to do it tell kubectl to use it: ```kubectl config use-context docker-desktop``` 
Check the cluser: ```kubectl get nodes```, to see info about all nodes in cluster.
When running locally, the only node will be your computer (and it runs both the control plane and acts as a worker node)

### Kubernetes Objects

PErsistenet entities we write to the cluster than record the intent. The cluser continuously checks these objects stored in it, and makes the state of the cluster match your intent.
We will use two kinds of objects here: 
1. kubernetes deployment
2. kubernetes service

### Kubernetes Deployment

Declarataive way to manage an application in kubernetes.
Declare docker images to run, how many copies to run, set their settings, configure the strategy for how to roll out updates to those images
K-deployment will then ensure all the requirements you declared are always met.

Containers are not deployed one at a time, they are deployed as Pods: groups of containers deployed together.

You might have one Pod of containers where one container runs a web app, and another container in that Pod gathers metrics on the web app.
We define and configure each Pod in the Pod Template block in main.tf's kubernetes_deployment resource.
For this example, the local kubernetes will work with just ONE pod.

### Kubernetes Service

Exposes a web app running in kubernetes as a networked service. 
example: Allows us to configure a load balancer to expose a public endopoint and distribute traffic from that endpoint all across the container/image copies in a kubernetes deployment.

Rather than use yamls, we'll be using Terraform module ```k8s-app``` to deploy an app using K-deployment an K-service.

Ok so now in the services/k8s-app directory I have the kubernetes deployment and service resources configured.
Then in the examples/kubernetes-local directly, I've set up a tiny tiny web-app image example that I will use to test the code right now by running INNIT then APPLY, from that directory.
After apply is successful test from the command line by running: ```curl http://localhost```, "Hello world!" should output tot he console

Exploring the Cluster:

To view the Kubernetes Deployment: ```kubectl get deployments```, will show the name we gave our deployment in the metadata block, and show us how many pods we have

To view the pods themselves: ```kubectl get pods```, to see the multiple container replicas running

All containers are being actively monitored and managed by kubernetes, if one crashes another will be deployed automatically.
To see this in action run ```docker ps```, grab a container ID and run ```docker kill <container_ID>``` to force shut it down.
A lightnight fast docker ps will show just one container remaining, but within seconds if you run it again you'll see the kubernetes deplyments has already launched a replacement!
The kubernetes load balancers is working to distribute traffic across these replica dontainers, we can see this with: ```kubectl get services```, which first shows the kubernetes service itself, then the loadbalancer

Kubernetes Deployments also have automatic update rollouts! 
For fun we'll set a PROVIDER ENV in our simple web app, and run apply again.


### Kubernetes in AWS using Elastic Kubernetes Service

So now we have a local cluster working with kubernetes, lets take this over to the AWS cloud.

We are setting up everything in the eks-cluster directory.

Once that's done, we will add a new examples to the "examples" directory at top level: kubernetes-eks.

I am going to wait to run terrafrom apply here, as I want to make sure I know how to tear this down and avoid charges in AWS first.

Ok, in examples/kubernetes-eks I'm running init, then apply. Let's see what happens!
Ah ok, no valid credential sources found error, this reminds me I need to go back and make sure my secrets are help properly.




# IMPORTANT KUBERNETES CAVEAT (from the book)!!

In the Kubernetes example, you had a single
module that deployed both the EKS cluster, using the AWS Provider, and a
Kubernetes app into that cluster, using the Kubernetes provider. As it turns
out, the Kubernetes provider documentation explicitly recommends against this
pattern:

```
When using interpolation to pass credentials to the Kubernetes provider from
other resources, these resources SHOULD NOT be created in the same Terraform
module where Kubernetes provider resources are also used. This will lead to
intermittent and unpredictable errors which are hard to debug and diagnose. The
root issue lies with the order in which Terraform itself evaluates the provider
blocks vs. actual resources.
```

The example code in this book is able to work around these issues by depending
on the aws_eks_cluster_auth data source, but that’s a bit of a hack. Therefore,
in production code, I always recommend deploying the EKS cluster in one
module and deploying Kubernetes apps in separate modules, after the cluster has
been deployed.

