set fallback := true

init:
    terraform init -backend-config=../../../global/config/backend.hcl

init-migrate:
    terraform init -backend-config=../../../global/config/backend.hcl -migrate-state

apply:
    terraform apply
plan:
    terraform plan
destroy:
    terraform destroy
