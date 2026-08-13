# Planes de mejora — stack AWS

Planes sobre **`iac/aws`** (cuenta real, `us-east-1`). No aplican a LocalStack. No son un backlog para implementar ahora: el lab sigue siendo apply → demo → destroy el mismo día ([ADR 010](../decisions.md)).

Marco: [AWS Well-Architected](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html) (Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, Sustainability).

| Plan | Pilar Well-Architected | Archivo |
|---|---|---|
| Arquitectura | Reliability, Performance Efficiency | [architecture.md](./architecture.md) |
| DevOps | Operational Excellence | [devops.md](./devops.md) |
| DevSecOps | Security | [devsecops.md](./devsecops.md) |
| FinOps | Cost Optimization, Sustainability | [finops.md](./finops.md) |

Hoy: [architecture.md](../architecture.md) · [costs-aws.md](../costs-aws.md) · ADR 006–011.

## Cómo leer cada ítem

- **Hoy:** qué hay en el HCL/scripts.
- **Práctica AWS:** control o patrón de referencia (WAFR, whitepaper, guía de servicio).
- **Cambio:** qué tocar en *este* repo.
- **Costo / ADR:** impacto vs Infracost (~USD 0.42 / 8 h, ~38 / 30 d) y si choca con un ADR.
- **Esfuerzo:** S < 4 h, M 4–12 h, L > 12 h (una persona).

## Prioridad si el lab dejara de ser efímero

| Pri | Qué | Por qué | Plan |
|---|---|---|---|
| P0 | HTTPS en el ALB (ACM) | HTTP en claro; el SG ya prevé 443 | DevSecOps, Arquitectura |
| P0 | Sacar el password de RDS del state | `random_password` queda en Terraform state | DevSecOps |
| P0 | Quitar `phpinfo.php` público | Divulgación de versiones/módulos | DevSecOps |
| P1 | SSM Session Manager + endpoint | Operar sin IP pública ni SSH | DevOps, Arquitectura |
| P1 | Gateway endpoint S3 | Egress a S3 sin NAT ni Internet | Arquitectura, FinOps |
| P1 | Checkov/tfsec + Infracost en CI | Drift y costo *antes* del apply | DevOps, FinOps |
| P1 | Backups RDS (`backup_retention` > 0) | Hoy `0` + `skip_final_snapshot` | Arquitectura |
| P2 | ASG desired ≥ 2 (una instancia por AZ) | Desired 1 = SPOF de compute | Arquitectura |
| P2 | RDS Multi-AZ | Variable ya existe; ~2× RDS | Arquitectura, FinOps |
| — | NAT Gateway | Prohibido como default ([ADR 007](../decisions.md)) | FinOps |

## No hacer en el lab (sin cambiar el Budget)

NAT Gateway (~USD 32 / 30 d), RDS Multi-AZ 24/7, WAF + Shield Advanced, GuardDuty/Security Hub prendidos un mes, Savings Plans, apply desde `app/` (`eu-west-1`). Cualquier ítem P2 exige re-scan Infracost y, si hace falta, subir el Budget de USD 5.
