#!/usr/bin/env bash
# Levanta LocalStack y espera health. Idempotente: si ya está healthy, no-op.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

CONTAINER="${LOCALSTACK_CONTAINER:-poc-cloud-foundation-localstack}"
HEALTH_URL="${LOCALSTACK_HEALTH_URL:-http://localhost:4566/_localstack/health}"
TIMEOUT="${LOCALSTACK_WAIT_SECONDS:-60}"

echo "==> 01_up: docker compose up -d (repo: ${ROOT})"
docker compose up -d

echo "==> esperando LocalStack healthy (${HEALTH_URL}, timeout ${TIMEOUT}s)"
deadline=$((SECONDS + TIMEOUT))
while (( SECONDS < deadline )); do
  if curl -sf "${HEALTH_URL}" >/dev/null 2>&1; then
    status="unknown"
    if docker inspect -f '{{.State.Health.Status}}' "${CONTAINER}" >/dev/null 2>&1; then
      status="$(docker inspect -f '{{.State.Health.Status}}' "${CONTAINER}")"
    fi
    echo "LocalStack listo (health=${status}). Endpoint: ${HEALTH_URL}"
    echo "Nada que crear si el contenedor ya corría: compose up es idempotente."
    exit 0
  fi
  sleep 2
done

echo "ERROR: LocalStack no respondió health en ${TIMEOUT}s" >&2
echo "Revisá: docker compose logs localstack" >&2
exit 1
