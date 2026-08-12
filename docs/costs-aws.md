# Costos — etapa AWS

Fuente: Infracost CLI **v2.16.1 en el host**, `infracost scan` con `infracost.yml` + `iac/aws/infracost-usage.yml` (ADR 011). Fecha: 12 ago 2026. Región `us-east-1`. Estimación, no factura.

```bash
./scripts/aws/infracost.sh
```

**Nunca** cotizar `iac/local` (Community = USD 0; el HCL se leería como AWS real). Login en el host, no en git.

## 8 h (destroy el mismo día) vs 30 d (olvidado)

Infracost cotiza 730 h. Sesión de lab: × 8/730. IPv4 de la EC2 no sale en el scan (IP autoasignada, no `aws_eip`).

| Recurso | 8 h | 30 d |
|---|---:|---:|
| ALB (0.0225 USD/h) | 0.18 | 16.43 |
| ALB LCU (usage lab) | ~0.00 | 0.01 |
| RDS `db.t4g.micro` Single-AZ | 0.13 | 11.68 |
| RDS gp3 20 GB | 0.03 | 2.30 |
| EC2 `t3.nano` × 1 | 0.04 | 3.80 |
| EBS gp3 8 GB | 0.01 | 0.64 |
| S3 (1 GB + requests) | ~0.00 | 0.03 |
| NAT Gateway | 0.00 | 0.00 |
| **Subtotal Infracost** | **0.38** | **34.88** |
| IPv4 público EC2 (no en scan) | 0.04 | 3.65 |
| **Total orden de magnitud** | **~0.42** | **~38.50** |

NAT no está en el HCL (ADR 007): se evitan ~USD 32/mes. Bootstrap (state + lock) no entra en este scan; costo ~0 sin usage.

## Guardrails

- Budget USD 5 al mail del grupo (A2).
- `02_apply.sh` muestra Infracost y pide confirmación.
- Apply → demo → `terraform -chdir=iac/aws destroy` el mismo día (ADR 010).
- Tags `Project`, `Environment=aws`, `ManagedBy=terraform`.

Free tier y descuentos de cuenta no aparecen. A las ~48 h de un apply, contrastar con Cost Explorer.
