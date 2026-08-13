# Plan de mejora — FinOps

Pilar: **Cost Optimization** y **Sustainability**. Números actuales: [costs-aws.md](../costs-aws.md) (Infracost 12 ago 2026: **USD 0.38 / 8 h**, **34.88 / 30 d**; +IPv4 ≈ **0.42 / 8 h**, **~38.50 / 30 d**). NAT = USD 0 a propósito ([ADR 007](../decisions.md)).

## Hoy

| Palanca | Estado |
|---|---|
| Región barata | `us-east-1` (ADR 006) |
| Sin NAT | Sí |
| RDS Graviton Single-AZ | `db.t4g.micro` |
| ASG mínimo | desired 1, `t3.nano`, credits standard, monitoring básico off |
| gp3 | EBS 8 GB y RDS 20 GB |
| Apply efímero + Budget USD 5 | ADR 010 |
| Infracost pre-apply | `02_apply.sh` + `infracost.yml` solo `iac/aws` |
| Tags | `Project`, `Environment=aws`, `ManagedBy=terraform` |
| IPv4 público EC2 | No está en el scan; ~USD 3.65 / 30 d |
| ALB | ~47 % del 30 d (USD 16.43) — el ancla de costo |

El 30 d “olvidado” lo dominan **ALB + RDS**, no el `t3.nano`. Optimizar la nano ahorra centavos; olvidar el destroy cuesta ~38 USD.

## Ítems

### F1 — Cerrar el ciclo Infracost → factura

- **Hoy:** scan pre-apply; a las ~48 h “contrastar con Cost Explorer” (costs-aws.md) sin script.
- **Práctica:** [FinOps Foundation](https://www.finops.org/) — Inform → Optimize → Operate. Estimación (Infracost) + actuals (Cost Explorer / CUR).
- **Cambio:** después de un apply de 8 h, `aws ce get-cost-and-usage` filtrado por tag `Environment=aws` (activar tag como cost allocation tag). Pegar el número en `costs-aws.md`. Infracost en el PR (comentario) además del script local.
- **Costo / ADR:** CE API ≈ 0. CUR + Athena es overkill para el lab.
- **Esfuerzo:** S.

### F2 — No introducir NAT; medir endpoints vs NAT

- **Hoy:** ADR 007. Un NAT GW us-east-1 ≈ USD 0.045/h + USD 0.045/GB ≈ **32+ / 30 d**.
- **Práctica:** [NAT vs VPC endpoints](https://aws.amazon.com/vpc/pricing/) — gateway S3/DynamoDB sin hourly; interface endpoints sí tienen hourly.
- **Cambio:** cualquier PR que agregue `aws_nat_gateway` falla el review. Tabla en el PR: NAT 30 d vs gateway S3 (0) vs 3× interface SSM (≈ 21 / 30 d en 1 AZ). Elegir A2, no NAT.
- **Costo / ADR:** evita el peor gasto del diseño Packt-like.
- **Esfuerzo:** S (norma de review).

### F3 — IPv4 y ALB (los dos costos “fijos”)

- **Hoy:** `map_public_ip_on_launch = true` en públicas. ALB siempre on-demand.
- **Práctica:** [Public IPv4 charge](https://aws.amazon.com/blogs/aws/new-aws-public-ipv4-address-charge-standard-public-ipv4-addresses-will-begin-incurring-charges/) USD 0.005/h. ALB no tiene stop: o destroy, o no tener ALB.
- **Cambio:** A2 (instancias privadas) elimina IPv4 de EC2; el ALB sigue teniendo IPs. Para un lab sin usuarios reales, el ALB es didáctico: **no** reemplazarlo por IP pública en la instancia (peor seguridad, ahorra ~16 USD/30 d pero rompe el diseño).
- **Costo / ADR:** A2 ahorra ~3.65 / 30 d. Destroy el mismo día ahorra los 16 del ALB.
- **Esfuerzo:** — (disciplina ADR 010) / M (A2).

### F4 — Graviton en EC2 y rightsizing

- **Hoy:** `t3.nano` x86; RDS ya `t4g`.
- **Práctica:** [Graviton cost](https://aws.amazon.com/ec2/graviton/). Credits `standard` ya está (no unlimited).
- **Cambio:** `t4g.nano` (A7). No subir a `t3.micro` “por si acaso”. Max 2 queda.
- **Costo / ADR:** ahorro chico vs ALB; coherencia con RDS.
- **Esfuerzo:** S.

### F5 — RDS: no pagar HA ni storage de más

- **Hoy:** 20 GB gp3, Single-AZ, `performance_insights_enabled = false`, backups 0.
- **Práctica:** Multi-AZ y PI son opt-in caros. Storage gp3 se factura provisionado, no usado.
- **Cambio:** no bajar de 20 GB (mínimo RDS). PI off. Multi-AZ solo con F1 re-scan y Budget ≥ 10. `aws rds stop-db-instance` existe (máx. 7 días) si alguien necesita dejar datos *sin* ALB: el ALB seguiría cobrando.
- **Costo / ADR:** stop RDS ahorra compute, no el ALB. Destroy sigue siendo más limpio.
- **Esfuerzo:** S.

### F6 — Budget más accionable

- **Hoy:** 80 % actual + 100 % forecast al mail. Límite USD 5.
- **Práctica:** [AWS Budgets](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html) + Cost Anomaly Detection. Varios umbrales (50/80/100). Filtro por tag `Project`.
- **Cambio:** notificación 50 %. Anomaly Detection en la cuenta (gratis hasta un número de anomalías). SNS → mail del grupo (ya). No Slack salvo que el grupo lo use.
- **Costo / ADR:** Budgets ≈ USD 0.02 / presupuesto / día después del primero… el primero es free. Con un solo budget, 0.
- **Esfuerzo:** S.

### F7 — Tags de allocation y “unit cost” del lab

- **Hoy:** tres tags. No están (necesariamente) activados como cost allocation tags.
- **Práctica:** [cost allocation tags](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html). Tag `Owner` / `Expiry`.
- **Cambio:** `Owner` = mail, `Service=lab`. Activar en Billing. Métrica del curso: **USD / demo de 8 h** (hoy ~0.42), no USD/mes.
- **Costo / ADR:** 0. El número de 8 h es el que hay que defender, no el 30 d.
- **Esfuerzo:** S.

### F8 — Sustainability (mismo diseño)

- **Hoy:** destroy el mismo día; nano; 1 AZ de RDS; región us-east-1 (grid más limpia que varias regiones, no es el criterio del lab).
- **Práctica:** [Sustainability pillar](https://docs.aws.amazon.com/wellarchitected/latest/sustainability-pillar/sustainability-pillar.html) — menos horas de compute, Graviton, no over-provision.
- **Cambio:** A7 + ADR 010. No “multi-región” por moda.
- **Costo / ADR:** alineado.
- **Esfuerzo:** S.

## Qué no optimizar

- **Spot** en un lab de 2 h de defensa: interrupción > ahorro.
- **Savings Plans / RI:** compromiso 1 año; el stack vive horas.
- **Sacar el ALB** para ahorrar: pierde el patrón del curso (lab ELB + SG).
- **Cotizar `iac/local`:** ADR 011.

## Orden sugerido

F2 (norma anti-NAT) → F6 (Budget 50 %) → F7 (tags + USD/8 h) → F1 (CE vs Infracost) → F4 (t4g.nano) → F3 vía A2.
