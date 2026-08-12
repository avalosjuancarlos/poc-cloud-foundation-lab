#!/usr/bin/env bash
# terraform init/validate/plan/apply en iac/local. Idempotente: el segundo apply no crea recursos.
# No hay secretos: credenciales dummy las pone el provider / el entorno del devcontainer.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IAC="${ROOT}/iac/local"

if ! command -v terraform >/dev/null 2>&1; then
  echo "ERROR: terraform no está en PATH. Rebuild del devcontainer (feature Terraform 1.15.8)." >&2
  exit 1
fi

echo "==> 02_apply: asegurando LocalStack"
"${ROOT}/scripts/local/01_up.sh"

echo "==> terraform -chdir=${IAC} init"
terraform -chdir="${IAC}" init -input=false

echo "==> terraform validate"
terraform -chdir="${IAC}" validate

echo "==> terraform plan"
terraform -chdir="${IAC}" plan -input=false -out="${IAC}/tfplan"

echo "==> terraform apply (auto-approve solo en local; ADR 004)"
terraform -chdir="${IAC}" apply -input=false "${IAC}/tfplan"
rm -f "${IAC}/tfplan"

echo
echo "Apply terminado. Outputs:"
terraform -chdir="${IAC}" output
echo
echo "La IP pública es emulada: no abras phpinfo (ADR 004)."
echo "Volvé a correr este script: el plan debe mostrar 0 to add."
