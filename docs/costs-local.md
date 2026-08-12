# Costos — etapa LocalStack

FinOps de la etapa 1. Factura cloud objetivo: **USD 0**. El único gasto real posible es aplicar `app/` (Packt) contra una cuenta AWS.

Estimaciones on-demand, orden de magnitud (ago 2026). No son una cotización.

## Qué se paga hoy

| Ítem | Precio | Notas |
|---|---|---|
| LocalStack Community 4.14.0 | USD 0 | API mock; no ejecuta user-data |
| Terraform OSS 1.15.8 | USD 0 | Pin en el devcontainer |
| Imagen Docker pineada | USD 0 | No usar `:latest` |
| boto3 / awscli-local / pytest | USD 0 | `requirements.txt` |
| Devcontainer en la notebook | USD 0 | ~1 GB RAM para LocalStack |
| GitHub Codespaces (opcional) | USD 0 hasta cuota | Free ~120 h/mes en 2-core; extra ~USD 0.18/h |
| Docker Desktop Personal / edu | USD 0 | Licencia comercial no aplica a uso ITBA personal |
| LocalStack Pro | no se usa | ~USD 30–100/user/mes; fuera de alcance |

Esfuerzo de implementación de esta etapa: ~18 h (costo académico USD 0). No es factura cloud.

## Cómo confirmar que el apply fue local

Después de `./scripts/local/02_apply.sh`:

1. El provider de `iac/local` solo tiene `endpoints` a `http://localhost:4566` y credenciales `test`/`test`.
2. `echo "$AWS_ENDPOINT_URL"` en el devcontainer debe ser `http://localhost:4566`.
3. La cuenta emulada suele ser `000000000000` (ARN del rol en `terraform output role_arn`).
4. No debe existir un profile `default` con keys reales en esa sesión. No exportes `AWS_ACCESS_KEY_ID` reales dentro del contenedor en esta etapa.

Si el apply hubiese ido a AWS real, verías recursos en la consola de `eu-west-1` (sample Packt) o en la región del profile, y una factura en Cost Explorer.

## Costo evitado: apply accidental de `app/` a AWS real

`app/main.tf` levanta `t3.nano` con IP pública en `eu-west-1`. VPC/IGW/SG no tienen cargo de servicio. Desde 2024 AWS cobra IPv4 público.

| Recurso | Driver | 24 h | 7 d | 30 d |
|---|---|---|---|---|
| EC2 t3.nano | ~USD 0.0052–0.0058 / h | 0.13 | 0.92 | 3.95 |
| IPv4 público | USD 0.005 / h | 0.12 | 0.84 | 3.60 |
| EBS gp3 ~8 GB | ~USD 0.08 / GB-mes | 0.02 | 0.15 | 0.64 |
| VPC, IGW, SG, IAM | sin cargo de servicio | 0.00 | 0.00 | 0.00 |
| **Total estimado** | si no se hace destroy | **0.27** | **1.91** | **8.19** |

No incluye data transfer ni NAT (este sample no usa NAT). RDS en una etapa futura cambia el orden de magnitud (~USD 12–15/mes un `db.t3.micro`).

Fuente: AWS On-Demand EC2, Public IPv4, EBS gp3 · us-east-1 / eu-west-1.

## Guardrails ya en el repo

- Apply canónico: `scripts/local/02_apply.sh` → `iac/local` (no `app/`).
- `iac/local/providers.tf` no tiene endpoints de AWS real.
- Tags `Environment=local`, `ManagedBy=terraform`, `t3.nano` (barato si alguien copia mal el HCL).
- `force_destroy` en el bucket local para poder `terraform destroy` sin residuos.
- State en disco, gitignore; no hay backend de prod.

## Apagar y no dejar basura

```bash
terraform -chdir=iac/local destroy
docker compose down
```

`compose down` no borra el volumen `localstack_data` salvo `docker compose down -v`. En local eso no factura; en aws, un destroy incompleto sí.

## Etapa aws (todavía no)

Cuando exista `iac/aws`, este documento no aplica: habrá presupuesto, tags de costo, backend con lock y revisión del SG `0.0.0.0/0` antes del apply.
