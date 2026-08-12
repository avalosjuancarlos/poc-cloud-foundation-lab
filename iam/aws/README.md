# `iam/aws/` — políticas del stack AWS real

Terraform en `iac/aws` las consume con `file()` / `templatefile()` (A5). No hay keys en la EC2: instance profile.

| Archivo | Tipo | Notas |
|---|---|---|
| `trust_policy.json` | Trust | EC2 asume el rol |
| `ec2_app_policy.json.tftpl` | Identity | Least privilege sobre **un** bucket |
| `bucket_policy.json.tftpl` | Resource | Principal = rol; **Deny** si `aws:SecureTransport=false` |

`${bucket_name}` y `${role_arn}` los interpola Terraform. El Deny TLS no está en `iam/local` porque LocalStack es HTTP (ADR 005 vs este stack).
