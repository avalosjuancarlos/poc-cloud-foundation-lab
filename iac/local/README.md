# `iac/local/` — stack LocalStack Community

Apply canónico de la etapa 1. Provider solo a `http://localhost:4566`.

Origen de red/compute: sample Packt en `app/` (AMI dummy, `us-east-1`, user-data referenciado).
IAM/S3: JSON en `iam/local/`.

```bash
# LocalStack healthy (compose)
docker compose up -d
docker compose ps

cd iac/local
terraform init
terraform validate
terraform plan
terraform apply
```

El E2E idempotente queda en `scripts/local/` (P6). `terraform destroy` limpia el state local (gitignore).
