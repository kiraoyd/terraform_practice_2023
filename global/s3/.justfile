set fallback := true

init:
    #this init uses backend config shared portions
    terraform init -backend-config=../config/backend.hcl

init-migrate:
    terraform init -backend-config=../config/backend.hcl -migrate-state

apply:
    terraform apply

plan:
    terraform plan

destroy:
    terraform destroy