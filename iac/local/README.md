# `iac/local/` — stack LocalStack Community

Apply canónico de la etapa 1. Provider solo a `http://localhost:4566`.

Origen de red/compute: sample Packt en `app/` (AMI dummy, `us-east-1`, user-data referenciado).
IAM/S3: JSON en `iam/local/`.

Camino E2E (idempotente):

```bash
./scripts/local/01_up.sh
./scripts/local/02_apply.sh
./scripts/local/03_verify.py
```

`terraform destroy` en este directorio limpia el state local (gitignore).
