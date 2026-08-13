# Plan de mejora — Arquitectura

Pilar: **Reliability** y **Performance Efficiency**. Topología actual: [architecture.md](../architecture.md). Decisiones que este plan no revierte: [ADR 007](../decisions.md) (sin NAT), [ADR 008](../decisions.md) (RDS Single-AZ default).

## Hoy

VPC `10.0.0.0/16`, 2 AZ. ALB + ASG `t3.nano` (desired 1, max 2) en subnets **públicas** (egress por IGW). RDS PostgreSQL 16 `db.t4g.micro` en privadas, Single-AZ, `publicly_accessible=false`. S3 regional. Health `/health`. User-data instala httpd+phpinfo. Sin VPC endpoints, sin Flow Logs, sin HTTPS.

## Ítems

### A1 — HTTPS en el ALB (ACM)

- **Hoy:** listener HTTP 80; el SG del ALB solo abre 80 (`security.tf`).
- **Práctica:** [ELB HTTPS listeners](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html); cert en ACM (us-east-1). Redirect 80 → 443.
- **Cambio:** `aws_acm_certificate` (DNS o email); listener 443; regla 80 redirect. Dominio (Route 53 o uno del grupo).
- **Costo / ADR:** ACM público USD 0. ALB no cambia de precio. El lab puede seguir en HTTP si no hay dominio.
- **Esfuerzo:** M (el DNS es el cuello).

### A2 — Compute privado + VPC endpoints (sin NAT)

- **Hoy:** ASG en públicas para que `dnf` y S3 salgan por IGW (ADR 007). IP pública en cada EC2.
- **Práctica:** [VPC endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html). Gateway endpoint **S3** (sin cargo por hora). Interface endpoints SSM (`ssm`, `ssmmessages`, `ec2messages`) si hay Session Manager. Repos de AL2023 viven en S3: con gateway S3 + policy de repos, `dnf` no necesita NAT.
- **Cambio:** ASG a subnets privadas; gateway endpoint S3; (opcional) interface SSM. ALB sigue en públicas. **No** crear NAT GW.
- **Costo / ADR:** Gateway S3 ≈ USD 0. Interface SSM ≈ USD 7 / endpoint / AZ / 30 d — caro para 8 h; en lab 1 AZ de endpoints o no ponerlos. Alinea ADR 007 (sigue sin NAT) y elimina IPv4 de la EC2 (~USD 3.65 / 30 d).
- **Esfuerzo:** M–L.

### A3 — ASG en dos AZ de verdad

- **Hoy:** subnets en 1a y 1b, `desired_capacity = 1` → una sola VM. ALB reparte, pero no hay réplica.
- **Práctica:** [ASG multiple AZs](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-add-availability-zone.html). Desired = número de AZ (o min 2).
- **Cambio:** `asg_desired_capacity = 2`, `asg_min_size = 2`. Health check ELB ya está.
- **Costo / ADR:** +1 × `t3.nano` + EBS + IPv4 ≈ USD 0.09 / 8 h, ~8 / 30 d. Choca con ADR 010 (desired 1) → nuevo ADR.
- **Esfuerzo:** S.

### A4 — RDS: backups y Multi-AZ como opt-in documentado

- **Hoy:** `backup_retention_period = 0`, `skip_final_snapshot = true`, `multi_az = var.db_multi_az` default false. Storage cifrado.
- **Práctica:** [RDS Multi-AZ](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html); retención ≥ 7 días en cargas reales; encryption at rest (ya).
- **Cambio:** lab: `backup_retention_period = 1` y snapshot final con nombre. “Prod”: `db_multi_az = true` (ya cableado).
- **Costo / ADR:** backup gp3 barato. Multi-AZ ≈ 2× instancia RDS (~USD 0.13 → 0.26 / 8 h; ~12 → 24 / 30 d). ADR 008 se mantiene como default; Multi-AZ es el camino de resiliencia de datos.
- **Esfuerzo:** S (variable); M (probar failover).

### A5 — Quitar phpinfo; app mínima que use RDS y S3

- **Hoy:** `user-data.sh` sirve phpinfo. RDS y S3 existen y casi no se usan en runtime.
- **Práctica:** el data plane tiene que ejercer los componentes que el diagrama muestra (RDS lab 08, S3 lab 06).
- **Cambio:** página `/` que haga `SELECT 1` a RDS (password por IAM/Secrets, no en user-data) y un `PutObject` de health a S3. Dejar `/health` para el ALB.
- **Costo / ADR:** ~0. Es el puente entre IaC y demo.
- **Esfuerzo:** M.

### A6 — Observabilidad de red y ALB

- **Hoy:** sin VPC Flow Logs; ALB sin access logs; `drop_invalid_header_fields = true`.
- **Práctica:** [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html); [ALB access logs](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html) a S3.
- **Cambio:** Flow Logs → CloudWatch (caro) o S3 (mejor FinOps). Access logs del ALB al bucket de logs (no el de la app).
- **Costo / ADR:** S3 logs centavos en 8 h; CloudWatch Logs se dispara. Preferir S3.
- **Esfuerzo:** S.

### A7 — Graviton también en compute

- **Hoy:** RDS `t4g.micro` (Graviton); ASG `t3.nano` x86. AMI `al2023-ami-2023.*-x86_64`.
- **Práctica:** [Graviton](https://docs.aws.amazon.com/whitepapers/latest/aws-graviton-performance-testing/what-is-aws-graviton.html) en EC2 compatible.
- **Cambio:** `t4g.nano` + AMI `aarch64`. User-data (httpd/php) corre igual en AL2023 arm64.
- **Costo / ADR:** `t4g.nano` suele ser ≤ `t3.nano` en us-east-1. Re-scan Infracost.
- **Esfuerzo:** S.

## Orden sugerido

A5 (demo real) → A1 (TLS) → A7 (Graviton) → A6 (logs) → A2 (privadas + endpoint S3) → A4 (backup) → A3 / Multi-AZ solo si hay Budget.
