# poc-cloud-foundation-lab

Proyecto integrador del módulo Cloud Computing (ITBA).

> **Integrantes:** _completar con los miembros del grupo_

Dos stacks (ADR 001): **local** (LocalStack Community, USD 0) y **aws** (`us-east-1`, ALB + ASG + RDS). El apply canónico nunca es `app/` (sample Packt en `eu-west-1`: costo + SG abierto).

---

## Local (devcontainer)

Rebuild del devcontainer. Compose levanta LocalStack al start.

```bash
./scripts/local/01_up.sh
./scripts/local/02_apply.sh
./scripts/local/03_verify.py
python3 -m pytest               # IAM siempre; smoke local si hay apply; smoke aws skip sin profile
```

**Éxito:** recursos en la API de LocalStack.  
**No es éxito:** `phpinfo.php`. Community no ejecuta `user-data.sh` ([ADR 004](docs/decisions.md)).

```bash
terraform -chdir=iac/local destroy
```

Detalle: [docs/architecture.md](docs/architecture.md) · [docs/costs-local.md](docs/costs-local.md) · [scripts/local/README.md](scripts/local/README.md)

---

## AWS real (host, profile `poc-aws`)

No mezclar con LocalStack ([ADR 009](docs/decisions.md)). Infracost y el named profile viven en el **host**. Si estás en el devcontainer, `01_creds` saca `AWS_ENDPOINT_URL` y las keys `test`.

```bash
aws configure --profile poc-aws          # region: us-east-1
./scripts/aws/01_creds.sh                # aborta si account 000000000000

cp iac/aws/bootstrap/terraform.tfvars.example iac/aws/bootstrap/terraform.tfvars
# editá budget_email
terraform -chdir=iac/aws/bootstrap init
terraform -chdir=iac/aws/bootstrap apply  # state + lock + Budget USD 5; no lo destruyas

cp iac/aws/backend.tf.example iac/aws/backend.tf
# ACCOUNT_ID = output account_id del bootstrap
cp iac/aws/terraform.tfvars.example iac/aws/terraform.tfvars

./scripts/aws/infracost.sh               # ~USD 34.88 / 30 d; ~0.38 / 8 h
./scripts/aws/02_apply.sh                # Infracost + plan; pide confirmación
./scripts/aws/03_verify.py               # API + http://<alb>/health
python3 -m pytest tests/aws
```

**Éxito:** `http://<alb_dns_name>/health` (phpinfo es extra).  
**Destroy el mismo día** ([ADR 010](docs/decisions.md)):

```bash
terraform -chdir=iac/aws destroy
```

No hagas destroy del bootstrap si queda state remoto. Nunca `terraform apply` en `app/`. Nunca `infracost scan iac/local`.

Costos: [docs/costs-aws.md](docs/costs-aws.md) · runbook corto: [scripts/aws/README.md](scripts/aws/README.md) · [iac/aws/README.md](iac/aws/README.md)

---

## Layout

```
.
├── .devcontainer/          # Python 3.12, Docker-in-Docker, AWS CLI, Terraform 1.15.8
├── compose.yaml            # LocalStack Community 4.14.0 (:4566) — no se usa en aws
├── app/                    # Baseline Packt (no apply)
├── iac/local/              # Terraform → LocalStack
├── iac/aws/                # Terraform → AWS us-east-1 (+ bootstrap/)
├── iam/local/  iam/aws/
├── scripts/local/  scripts/aws/
├── tests/local/  tests/aws/
├── infracost.yml           # solo iac/aws (ADR 011)
└── docs/                   # architecture, decisions, costs-local, costs-aws
```

---

## Checklist del proyecto

Etapa local:

- [x] `docs/architecture.md` con diagrama y componentes
- [x] `docs/decisions.md` con al menos 5 ADR
- [x] `iam/` con trust + policies + bucket policy (`iam/local/`)
- [x] `scripts/` con al menos 3 demos idempotentes (`scripts/local/`)
- [x] `compose.yaml` con LocalStack
- [x] Tests (`pytest` en el devcontainer)
- [x] README explicando cómo correrlo end-to-end
- [x] `docs/costs-local.md` (FinOps etapa local)

Etapa AWS:

- [x] Diagrama AWS + ADR 006–011
- [x] `iam/aws/` (trust, least privilege, Deny TLS)
- [x] `scripts/aws/` (`01_creds`, `02_apply`, `03_verify`)
- [x] `tests/aws/` (skip sin credenciales)
- [x] README E2E: profile + unset endpoint + Infracost + apply + destroy
- [x] `docs/costs-aws.md` desde Infracost (`iac/aws`, no `iac/local`)
- [x] RDS PostgreSQL fuera de la EC2; sin NAT Gateway

---

## Referencias del curso

- Repo de demos por clase: [cloud-foundations-lab](https://github.com/maxflorentin/cloud-foundations-lab)
- AWS Academy Cloud Architecting (Spanish LATAM)
- Labs 04 (IAM), 05 (EC2), 06 (S3), 07 (VPC), 08 (RDS)
- Sample Packt en `app/`: [Building Resilient Architectures on AWS](https://github.com/PacktPublishing/Building-Resilient-Architectures-on-AWS)
