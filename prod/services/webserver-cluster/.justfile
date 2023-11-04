set fallback := true

init:
    terraform init -backend-config=../../../global/config/backend.hcl

apply:
    terraform apply

plan:
    terraform plan

destroy:
    terraform destroy