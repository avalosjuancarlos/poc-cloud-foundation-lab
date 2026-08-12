#!/usr/bin/env bash
# Cotiza iac/aws con el Infracost del host. Nunca iac/local (ADR 011).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "${ROOT}"

if [[ "${1:-}" == *local* ]]; then
  echo "ERROR: prohibido cotizar iac/local (ADR 011). Community = USD 0." >&2
  exit 1
fi

unset AWS_ENDPOINT_URL || true
if [[ "${AWS_ACCESS_KEY_ID:-}" == "test" ]]; then
  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN || true
fi

if ! command -v infracost >/dev/null 2>&1; then
  echo "ERROR: infracost no está en PATH. En este lab se usa el CLI del host, no el devcontainer." >&2
  exit 1
fi

echo "==> infracost $(infracost version 2>/dev/null | head -1)"
echo "    config: infracost.yml  usage: iac/aws/infracost-usage.yml"
# v2.16: scan desde la raíz para que tome infracost.yml (usage_file + solo iac/aws).
# No pasar iac/aws como path: autodectaría bootstrap y ignoraría el usage file.
infracost scan --currency USD --no-color "$@"
