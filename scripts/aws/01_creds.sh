#!/usr/bin/env bash
# Deja el entorno listo para AWS real: sin LocalStack, profile poc-aws (ADR 009).
# Se puede sourcear desde 02_apply / 03_verify para exportar las variables.
set -euo pipefail

echo "==> 01_creds: quitando overlay LocalStack del devcontainer"

unset AWS_ENDPOINT_URL || true
if [[ "${AWS_ACCESS_KEY_ID:-}" == "test" ]]; then
  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN || true
  echo "Keys dummy (test) removidas; se usará el profile."
fi

export AWS_PROFILE="${AWS_PROFILE:-poc-aws}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
export AWS_EC2_METADATA_DISABLED="${AWS_EC2_METADATA_DISABLED:-true}"

echo "AWS_PROFILE=${AWS_PROFILE}"
echo "AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}"
echo "AWS_ENDPOINT_URL=${AWS_ENDPOINT_URL:-<unset>}"

if ! command -v aws >/dev/null 2>&1; then
  echo "ERROR: aws CLI no está en PATH." >&2
  exit 1
fi

ident="$(aws sts get-caller-identity --output json)"
echo "${ident}"

account="$(aws sts get-caller-identity --query Account --output text)"
if [[ "${account}" == "000000000000" ]]; then
  echo "ERROR: account 000000000000 — seguís en LocalStack. Revisá AWS_ENDPOINT_URL y el profile." >&2
  exit 1
fi

echo "OK cuenta ${account}. Podés aplicar iac/aws/bootstrap o iac/aws."
