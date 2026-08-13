# Plan de mejora — DevOps

Pilar: **Operational Excellence**. Hoy el apply es humano en el host, profile `poc-aws`, scripts `01_creds` / `02_apply` / `03_verify` ([ADR 009](../decisions.md)).

## Hoy

- Terraform 1.x, state remoto S3 + lock DynamoDB (bootstrap).
- `02_apply.sh`: Infracost + plan + confirmación (no auto-approve).
- Tests pytest: IAM siempre; smoke AWS skip sin profile / si account `000000000000`.
- Sin CI, sin OIDC, sin SSM, AMI + user-data en cada launch, sin alarmas CloudWatch.
- Destroy es el runbook; no hay TTL automático si alguien olvida el stack.

## Ítems

### D1 — CI de *control plane* (sin apply a la cuenta)

- **Hoy:** fmt/validate/tests solo en la máquina del alumno.
- **Práctica:** [CI/CD for Terraform](https://docs.aws.amazon.com/prescriptive-guidance/latest/terraform-aws-provider-best-practices/security.html) — plan en PR, apply solo con aprobación.
- **Cambio:** GitHub Actions: `terraform fmt -check`, `validate` en `iac/aws` y `iac/aws/bootstrap`, `tflint`, `pytest tests` (AWS skip). **No** `terraform apply` desde CI contra la cuenta del lab.
- **Costo / ADR:** USD 0 (runners de GitHub). No pisa ADR 010.
- **Esfuerzo:** S.

### D2 — OIDC (IAM Identity Center o GitHub OIDC) en lugar de keys largas

- **Hoy:** named profile con access keys en el host.
- **Práctica:** [IAM Roles Anywhere / GitHub OIDC](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html); no guardar keys en disco.
- **Cambio:** rol `poc-aws-operator` asumible por el IdP del grupo o por `github.com` + `sub` acotado al repo. El profile local usa `credential_source` o `aws sso login`.
- **Costo / ADR:** USD 0. Sustituye el procedimiento de `aws configure --profile poc-aws`, no el unset de `AWS_ENDPOINT_URL`.
- **Esfuerzo:** M.

### D3 — SSM Session Manager (operar sin SSH)

- **Hoy:** sin key pair, sin puerto 22. Si hay que debuggear user-data, no hay canal.
- **Práctica:** [Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html). IAM `AmazonSSMManagedInstanceCore` en el instance profile; endpoints si la instancia es privada (A2).
- **Cambio:** attach de la managed policy (o JSON en `iam/aws`); SG de app **sigue** sin 22. Documentar `aws ssm start-session` en `scripts/aws/README.md`.
- **Costo / ADR:** Session Manager USD 0. Endpoints: ver A2. Compatible con “no SSH”.
- **Esfuerzo:** S (públicas) / M (privadas).

### D4 — AMI inmutable (Packer) en vez de user-data largo

- **Hoy:** launch template + `user-data.sh` (dnf httpd php en cada scale-out). Grace 300 s.
- **Práctica:** [immutable infrastructure](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_immutable_infrastructure.html) — bake AMI, user-data solo config.
- **Cambio:** Packer (AL2023) publica AMI en la cuenta; `data.aws_ami` filtra por tag `Project`. Pipeline opcional.
- **Costo / ADR:** build ~minutos de `t3.micro`. Scale-out más rápido; health del ALB deja de esperar yum.
- **Esfuerzo:** M.

### D5 — Alarmas y dashboard mínimos

- **Hoy:** health check ELB en el ASG; Budget USD 5. Sin alarma de UnHealthyHostCount ni RDS `CPUUtilization` / `FreeStorageSpace`.
- **Práctica:** [CloudWatch alarms for ALB/ASG/RDS](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html).
- **Cambio:** 3–4 alarmas → SNS al mismo mail del Budget. No hace falta Grafana.
- **Costo / ADR:** alarmas ~USD 0.10 c/u / 30 d. En 8 h irrelevante.
- **Esfuerzo:** S.

### D6 — TTL / destroy de seguridad

- **Hoy:** disciplina humana + Budget. Un ALB+RDS olvidado ≈ USD 38 / 30 d.
- **Práctica:** [Instance Scheduler](https://aws.amazon.com/solutions/implementations/instance-scheduler-on-aws/) o EventBridge + Lambda `terraform destroy` / stop RDS+ASG. AWS no apaga un ALB solo.
- **Cambio (lab):** EventBridge rule “hoy 23:59 ART” que publica a SNS “¿sigue el stack?”. Más agresivo: tag `DestroyAfter` + script en el host (cron), no Lambda 24/7.
- **Costo / ADR:** SNS ≈ 0. Lambda permanente es otro recurso que olvidar. Preferir recordatorio, no un segundo control plane.
- **Esfuerzo:** S (SNS) / M (auto-destroy).

### D7 — Módulos y entornos (cuando haya más que un lab)

- **Hoy:** un árbol `iac/aws` + bootstrap. ADR 001 prohíbe unificar con LocalStack.
- **Práctica:** módulos por VPC/ALB/RDS; workspaces o carpetas `dev`/`prod` **dentro de AWS**, no mezclar con `iac/local`.
- **Cambio:** solo si aparece un segundo entorno AWS. No extraer módulos “por estética”.
- **Costo / ADR:** 0. Respetar ADR 001.
- **Esfuerzo:** L (cuando haga falta).

### D8 — State: hardening del bootstrap

- **Hoy:** bucket versionado, AES256, public access block, DynamoDB lock. Sin bucket policy TLS deny (el de la app sí la tiene). `force_destroy = false`.
- **Práctica:** misma Deny `aws:SecureTransport` que `iam/aws/bucket_policy.json.tftpl`; access logs del state a otro bucket; lock de eliminación.
- **Cambio:** policy en `iac/aws/bootstrap`. No destroy del bootstrap si queda state.
- **Costo / ADR:** ≈ 0.
- **Esfuerzo:** S.

## Orden sugerido

D1 (CI) → D8 (state TLS) → D3 (SSM) → D5 (alarmas) → D6 (recordatorio destroy) → D2 (OIDC) → D4 (Packer).
