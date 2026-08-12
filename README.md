# poc-cloud-foundation-lab

Proyecto integrador del módulo Cloud Computing (ITBA).

> **Integrantes:** _completar con los miembros del grupo_

Etapa actual: **LocalStack Community** (local-first). VPC + IAM + S3 + EC2 emulado. AWS real es otra carpeta (`iac/aws`), todavía no.

El apply canónico es `iac/local`, no `app/`. `app/` es el sample de Packt contra AWS real (`eu-west-1`): no lo apliques (costo + SG abierto).

---

## Cómo correrlo end-to-end

Todo en el **devcontainer** (rebuild si acabás de clonar). Compose levanta LocalStack al start; Terraform y pytest viven en el contenedor.

```bash
./scripts/local/01_up.sh        # LocalStack healthy en :4566
./scripts/local/02_apply.sh     # terraform apply en iac/local
./scripts/local/03_verify.py    # VPC, EC2, rol, bucket por tag
python3 -m pytest               # IAM siempre; smoke si el stack está aplicado
```

Segunda corrida de `02_apply` / `03_verify`: idempotente (0 creates).

**Éxito:** recursos visibles en la API de LocalStack.  
**No es éxito:** abrir `http://<public_ip>/phpinfo.php`. Community no ejecuta `user-data.sh` ([ADR 004](docs/decisions.md)).

Si el smoke de pytest dice que no hay VPC/instancia/rol: el control plane está vacío. Corré `02_apply.sh` y repetí `pytest` ([tests/local/README.md](tests/local/README.md)).

Destroy del stack local:

```bash
terraform -chdir=iac/local destroy
```

---

## Layout

```
.
├── .devcontainer/          # Python 3.12, Docker-in-Docker, AWS CLI, Terraform 1.15.8
├── compose.yaml            # LocalStack Community 4.14.0 (:4566)
├── app/                    # Baseline Packt (no apply)
├── iac/local/              # Terraform contra LocalStack
├── iam/local/              # Trust + identity + bucket policy
├── scripts/local/          # 01_up, 02_apply, 03_verify
├── tests/local/            # pytest (correr en el devcontainer)
├── docs/
│   ├── architecture.md
│   └── decisions.md
└── requirements.txt
```

Detalle: [docs/architecture.md](docs/architecture.md) · [iac/local/README.md](iac/local/README.md) · [scripts/local/README.md](scripts/local/README.md)

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

Pendiente de etapas siguientes: stack `*/aws`, RDS, doc de costos (`docs/costs-local.md`).

---

## Referencias del curso

- Repo de demos por clase: [cloud-foundations-lab](https://github.com/maxflorentin/cloud-foundations-lab)
- AWS Academy Cloud Architecting (Spanish LATAM)
- Labs 04 (IAM), 05 (EC2), 06 (S3), 07 (VPC), 08 (RDS)
- Sample Packt en `app/`: [Building Resilient Architectures on AWS](https://github.com/PacktPublishing/Building-Resilient-Architectures-on-AWS)
