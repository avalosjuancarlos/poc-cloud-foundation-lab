#!/usr/bin/env bash
# terraform init/validate/plan/apply en iac/aws. Muestra Infracost y pide confirmación (ADR 011).
# No auto-approve. No aplica app/. Idempotente: el segundo apply no crea recursos de más.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IAC="${ROOT}/iac/aws"

# shellcheck source=01_creds.sh
source "${ROOT}/scripts/aws/01_creds.sh"

if ! command -v terraform >/dev/null 2>&1; then
  echo "ERROR: terraform no está en PATH." >&2
  exit 1
fi

if [[ ! -f "${IAC}/backend.tf" ]]; then
  echo "ERROR: falta ${IAC}/backend.tf" >&2
  echo "  cp iac/aws/backend.tf.example iac/aws/backend.tf" >&2
  echo "  # reemplazá ACCOUNT_ID con el output account_id del bootstrap" >&2
  exit 1
fi

if [[ ! -f "${IAC}/terraform.tfvars" ]]; then
  echo "ERROR: falta ${IAC}/terraform.tfvars (no se commitea)." >&2
  echo "  cp iac/aws/terraform.tfvars.example iac/aws/terraform.tfvars" >&2
  exit 1
fi

if [[ "${SKIP_INFRACOST:-}" == "1" ]]; then
  echo "WARN: SKIP_INFRACOST=1 — no se cotizó. Ver docs/costs-aws.md (~USD 0.38 / 8 h, ~35 / 30 d)."
else
  echo "==> Infracost (ADR 011)"
  "${ROOT}/scripts/aws/infracost.sh"
  echo
  echo "Tabla del lab: docs/costs-aws.md  (~USD 0.38 / 8 h si hay destroy; ~USD 35 / 30 d si no)."
fi

echo "==> terraform -chdir=${IAC} init"
terraform -chdir="${IAC}" init -input=false

echo "==> terraform validate"
terraform -chdir="${IAC}" validate

echo "==> terraform plan"
terraform -chdir="${IAC}" plan -input=false -out="${IAC}/tfplan"

echo
echo "Apply a AWS real (us-east-1). Destroy el mismo día (ADR 010)."
if [[ "${CONFIRM_APPLY:-}" == "yes" ]]; then
  echo "CONFIRM_APPLY=yes — siguiendo."
else
  if [[ ! -t 0 ]]; then
    echo "ERROR: no hay TTY. Exportá CONFIRM_APPLY=yes para aplicar, o abortá." >&2
    rm -f "${IAC}/tfplan"
    exit 1
  fi
  read -r -p "¿Apply? [y/N] " ans
  if [[ "${ans}" != "y" && "${ans}" != "Y" ]]; then
    echo "Abortado. No se aplicó nada."
    rm -f "${IAC}/tfplan"
    exit 0
  fi
fi

echo "==> terraform apply"
terraform -chdir="${IAC}" apply -input=false "${IAC}/tfplan"
rm -f "${IAC}/tfplan"

echo
echo "Apply terminado. Outputs (password sensible, no se imprime acá):"
terraform -chdir="${IAC}" output -json | python3 -c '
import json, sys
d = json.load(sys.stdin)
for k, v in d.items():
    if v.get("sensitive"):
        print(f"{k} = <sensitive>")
    else:
        print(f"{k} = {v.get("value")}")
'
echo
echo "Verify: ./scripts/aws/03_verify.py"
echo "Destroy hoy: terraform -chdir=iac/aws destroy"
echo "Volvé a correr este script: el plan debe mostrar 0 to add."
