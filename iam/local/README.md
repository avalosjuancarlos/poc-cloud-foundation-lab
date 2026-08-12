# `iam/local/` — políticas del stack LocalStack

Terraform en `iac/local` las consume con `file()` / `templatefile()` (ADR 005). No hay keys: el compute asume un rol.

| Archivo | Tipo | Notas |
|---|---|---|
| `trust_policy.json` | Trust | EC2 puede asumir el rol |
| `ec2_app_policy.json.tftpl` | Identity | Least privilege: List/Get/Put/Delete en **un** bucket (`${bucket_name}`) |
| `bucket_policy.json.tftpl` | Resource | Principal = ARN del rol (`${role_arn}`) |

`${bucket_name}` y `${role_arn}` los interpola Terraform en el apply.

No se incluye `Deny` por `aws:SecureTransport`: LocalStack habla HTTP en `:4566`. Esa condición va en `iam/aws` cuando exista.
