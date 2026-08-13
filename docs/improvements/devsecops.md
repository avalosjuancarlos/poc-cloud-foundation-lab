# Plan de mejora — DevSecOps

Pilar: **Security**. Ya hay: IMDSv2 required, SG app solo desde SG ALB, RDS no pública, S3 Block Public Access + Deny TLS, instance profile (sin keys en la VM), `drop_invalid_header_fields` en el ALB, scripts que abortan account `000000000000`.

## Hoy (huecos)

- ALB HTTP 80 a `0.0.0.0/0`.
- `phpinfo.php` público.
- Password RDS en `random_password` → state de Terraform (output sensitive, igual está en S3).
- Egress app `0.0.0.0/0` `-1`.
- Trust de EC2 sin `aws:SourceAccount` / `aws:SourceArn`.
- App bucket sin versionado. RDS `deletion_protection = false`, backups 0.
- Sin CloudTrail/GuardDuty/Config (cuenta). Sin WAF. Sin Checkov en CI.
- User-data no corre como root-only issue, pero instala paquetes desde Internet en cada boot.

## Ítems

### S1 — TLS en tránsito (ALB) y dejar 80 solo como redirect

- **Hoy:** único listener 80.
- **Práctica:** [Protect data in transit](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/protect-data-in-transit.html). TLS 1.2+ en el ALB; HTTP→HTTPS.
- **Cambio:** ver A1. Política `ELBSecurityPolicy-TLS13-1-2-2021-06` (o la vigente).
- **Costo / ADR:** ACM 0. El SG 443 se suma; 80 puede quedar solo para redirect.
- **Esfuerzo:** M.

### S2 — Secretos fuera del state

- **Hoy:** `random_password.db` en `rds.tf`; Terraform lo guarda en el backend.
- **Práctica:** [Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/integrating_csi_rds.html) o SSM Parameter `SecureString` (KMS). RDS manage_master_user_password (AWS genera y rota).
- **Cambio:** `manage_master_user_password = true` (RDS + Secrets Manager nativo) **o** `aws_secretsmanager_secret` + IAM GetSecretValue en el rol de instancia. Quitar el output de password.
- **Costo / ADR:** Secrets Manager ≈ USD 0.40 / secreto / 30 d + API. En 8 h ≈ 0. En lab, SSM Parameter es más barato (KMS).
- **Esfuerzo:** S–M.

### S3 — Superficie de la app: phpinfo y headers

- **Hoy:** `phpinfo.php` en el docroot.
- **Práctica:** no exponer `phpinfo` ni versiones. Security headers en el ALB (o httpd): HSTS cuando haya TLS.
- **Cambio:** borrar phpinfo del user-data; `/health` alcanza. Opcional: `aws_lb_listener_rule` que 404 a `/phpinfo.php`.
- **Costo / ADR:** 0. El README hoy dice “phpinfo es extra”: hay que cambiar el criterio de demo (A5).
- **Esfuerzo:** S.

### S4 — Least privilege fino (IAM + egress)

- **Hoy:** trust solo `ec2.amazonaws.com`. Policy S3 List/Get/Put/Delete al bucket del proyecto. Egress IPv4 all.
- **Práctica:** [confused deputy](https://docs.aws.amazon.com/IAM/latest/UserGuide/confused-deputy.html) (`aws:SourceAccount` en el trust). Egress mínimo: 443 a dnf/S3 y 5432 al SG RDS (el 5432 ya está en el SG de RDS, no hace falta abrirlo en egress si se deja all; el valor es **restringir** egress).
- **Cambio:** condición en `iam/aws/trust_policy.json`. Egress app: 443/tcp 0.0.0.0/0 + 5432 al SG RDS; quitar `-1`. Prefix lists de S3 si hay gateway endpoint (A2).
- **Costo / ADR:** 0. `dnf` se rompe si se olvida 443 o el endpoint S3.
- **Esfuerzo:** S.

### S5 — Cifrado y versionado S3 / KMS

- **Hoy:** AES256 (SSE-S3) en app y tfstate. App bucket `force_destroy = true`, sin versionado.
- **Práctica:** versionado en buckets con datos; SSE-KMS si hay requisito de CMK/auditoría. Bucket keys para baratar KMS.
- **Cambio:** versionado en app (lab: lifecycle expire 7 d). tfstate ya versiona. KMS solo si el curso lo pide (lab 04/06 no lo exigen).
- **Costo / ADR:** versionado ≈ 0 en 8 h. CMK ≈ USD 1 / 30 d.
- **Esfuerzo:** S.

### S6 — Guardrails de cuenta (Trail, Config, GuardDuty)

- **Hoy:** Budget. Nada de detective controls.
- **Práctica:** CloudTrail (organización o cuenta) a S3; [GuardDuty](https://docs.aws.amazon.com/guardduty/latest/ug/what-is-guardduty.html); AWS Config rules (`encrypted-volumes`, `restricted-ssh`, `s3-bucket-ssl-requests-only`).
- **Cambio:** Trail de 8 h es didáctico; **apagado en el destroy**. GuardDuty/Config 30 d no entran en USD 5.
- **Costo / ADR:** Trail S3 barato. GuardDuty ~USD 4–10 / 30 d en cuenta vacía+lab. Config según ítems. Solo con Budget más alto o cuenta Academy.
- **Esfuerzo:** M.

### S7 — WAF en el ALB

- **Hoy:** ALB expuesto a Internet en 80.
- **Práctica:** [AWS WAF](https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html) managed rules (Common Rule Set, known bad inputs). Rate limit.
- **Cambio:** `aws_wafv2_web_acl` asociado al ALB. Para el lab, **IP set allowlist** del egreso del grupo (más barato y más efectivo que WAF managed).
- **Costo / ADR:** WAF ACL + reglas managed ≈ USD 8–15 / 30 d + requests. Allowlist de SG/ALB: 0. Preferir allowlist en el lab; WAF si hay defensa pública.
- **Esfuerzo:** S (allowlist) / M (WAF).

### S8 — IaC scanning (Checkov / tfsec) y secret scanning

- **Hoy:** pytest de JSON IAM. No hay SAST de HCL.
- **Práctica:** Checkov CIS AWS; git secret scanning (GitHub). Nunca commitear `terraform.tfvars` (ya gitignore).
- **Cambio:** job en D1. Baseline: fallar en `CKV_AWS_2` (ALB HTTP), `CKV_AWS_23` (SG), RDS backups. Documentar skips con el ADR (p. ej. HTTP 80 del lab).
- **Costo / ADR:** 0. Los skips tienen que citar ADR, no silenciar todo.
- **Esfuerzo:** S.

### S9 — Patch y runtime

- **Hoy:** `dnf install` al boot; sin parches posteriores. `monitoring { enabled = false }` (detalle CloudWatch).
- **Práctica:** SSM Patch Manager o AMI reciente (D4). IMDSv2 ya está (`http_tokens = required`, hop limit 1).
- **Cambio:** data source de AMI ya usa `most_recent`. Fijar un SSM association es overkill en 8 h; en un stack que viva, sí.
- **Costo / ADR:** 0 en el lab si se destroy el mismo día.
- **Esfuerzo:** S (documentar) / M (Patch Manager).

## Orden sugerido

S3 (phpinfo) → S8 (Checkov) → S4 (trust + egress) → S2 (secretos) → S1 (TLS) → S5 (versionado) → S7 allowlist → S6/S7 WAF solo fuera del Budget de USD 5.
