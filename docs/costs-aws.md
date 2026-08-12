# Costos — etapa AWS

Fuente: Infracost CLI **v2.16.1 en el host** (no en el devcontainer), `infracost scan` con `infracost.yml` + `iac/aws/infracost-usage.yml` (ADR 011). Fecha: 12 ago 2026. Región `us-east-1`. Estimación mensual (730 h), no factura.

```bash
./scripts/aws/infracost.sh
# equivalente: infracost scan   # desde la raíz del repo
```

**Nunca** `infracost scan iac/local` ni pasar `iac/local` al script: LocalStack Community es USD 0 y el parser leería el HCL como AWS real. El scan se lanza desde la raíz para que tome el config (solo `iac/aws` + usage).

Login/`INFRACOST_API_KEY` quedan en el host. No van a git.

## Stack de aplicación (olvidado 30 d)

| Recurso | Driver Infracost | USD / 30 d |
|---|---|---|
| ALB (`aws_lb.app`) | 0.0225 USD/h × 730 h | 16.43 |
| ALB LCU | usage: 1 GB + 1 conn/s (lab) | 0.01 |
| RDS PostgreSQL `db.t4g.micro` Single-AZ | 0.016 USD/h × 730 h | 11.68 |
| RDS storage gp3 20 GB | 0.115 USD/GB-mes | 2.30 |
| EC2 `t3.nano` × 1 (ASG desired) | 0.0052 USD/h × 730 h | 3.80 |
| EBS gp3 8 GB (root) | 0.08 USD/GB-mes | 0.64 |
| S3 app | usage: 1 GB + 1k PUT/GET | 0.03 |
| NAT Gateway | **no está en el HCL** (ADR 007) | 0.00 |
| **Total scan** | | **34.88** |

8 h con destroy el mismo día: `34.88 × 8 / 730 ≈ USD 0.38`.

## Lo que el scan no cubre

- IPv4 público de la EC2 (~USD 0.005/h, ~3.60 / 30 d) no tiene usage key en este HCL (IP autoasignada, no `aws_eip`). El ALB también puede sumar IPv4.
- Free tier y descuentos de la cuenta no entran.
- Bootstrap no entra en este scan (el config apunta solo al stack de aplicación).

Orden de magnitud con IPv4: ~USD 0.42 / 8 h; ~USD 38 / 30 d si no hay destroy.

## Guardrails

- Budget USD 5 (A2) al mail del grupo.
- Apply efímero + destroy el mismo día (ADR 010).
- Tags `Project`, `Environment=aws`, `ManagedBy=terraform`.

Después del primer apply, contrastar con Cost Explorer (~48 h). A10 deja el runbook E2E en el README.
