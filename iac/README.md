# `iac/` — Infrastructure as Code

Stacks separados (ADR 001). No hay un `main.tf` parametrizado local vs aws.

```
iac/
├── local/                 ← etapa 1: LocalStack (apply canónico)
├── providers/             ← ejemplos del starter (azure/gcp); AWS local está en local/providers.tf
├── main.tf                ← no aplicar desde acá
├── variables.tf
└── outputs.tf
```

## LocalStack

```bash
cd iac/local
terraform init
terraform plan
terraform apply
```

Requiere LocalStack en `:4566` (`compose.yaml`). Detalle: `iac/local/README.md`.

## AWS real

`iac/aws/` se agrega en la etapa 2. No compartir módulos con `local/`.

## Convenciones

- **No commitear `.tfstate`** (ya está en .gitignore)
- **Variables tipadas** — `terraform validate`
- **Backend remoto** solo en el stack aws (S3 + DynamoDB lock)
