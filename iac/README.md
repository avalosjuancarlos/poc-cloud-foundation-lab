# `iac/` — Infrastructure as Code

Stacks separados (ADR 001). No hay un `main.tf` parametrizado local vs aws.

```
iac/
├── local/                 ← LocalStack
├── aws/
│   ├── bootstrap/         ← state S3 + lock DynamoDB + Budget (A2)
│   └── …                  ← VPC/ALB/RDS (A4–A6)
├── providers/
├── main.tf                ← no aplicar desde acá
├── variables.tf
└── outputs.tf
```

## LocalStack

```bash
./scripts/local/02_apply.sh
```

## AWS real

```bash
./scripts/aws/01_creds.sh
# bootstrap: ver iac/aws/README.md
```

No compartir módulos entre `local/` y `aws/`.

## Convenciones

- **No commitear `.tfstate` ni `iac/aws/terraform.tfvars`**
- **Backend remoto** solo en el stack de aplicación aws (después del bootstrap)
