# `iac/` — Infrastructure as Code

Stacks separados (ADR 001). No hay un `main.tf` parametrizado local vs aws.

```
iac/
├── local/                 ← LocalStack
├── aws/
│   ├── bootstrap/         ← state S3 + lock DynamoDB + Budget (A2)
│   ├── network.tf         ← VPC 2 AZ, públicas + privadas, sin NAT (A4)
│   ├── data.tf / rds.tf    ← S3 + RDS PostgreSQL t4g.micro (A5)
│   └── alb.tf / compute.tf ← ALB + ASG t3.nano (A6)
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
./scripts/aws/infracost.sh   # host; nunca iac/local
```

No compartir módulos entre `local/` y `aws/`.

## Convenciones

- **No commitear `.tfstate` ni `iac/aws/terraform.tfvars`**
- **Backend remoto** solo en el stack de aplicación aws (después del bootstrap)
