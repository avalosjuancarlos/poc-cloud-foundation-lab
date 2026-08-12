# `tests/aws/` — pytest del stack AWS real

Políticas IAM: siempre (no pegan a la red). Smoke boto3/HTTP: **skip** si no hay profile `poc-aws` o si la cuenta es LocalStack (`000000000000`).

```bash
# host, con profile poc-aws (después de 02_apply)
python3 -m pytest tests/aws
```

En el **devcontainer** (`python3 -m pytest`) las IAM de aws corren; el smoke se salta por keys `test` / sin profile.

Si el smoke corre y falla:

- `no hay VPC ... Environment=aws` → no se aplicó `iac/aws`
- ALB `/health` timeout → user-data todavía no terminó; `./scripts/aws/03_verify.py` espera más

No uses `AWS_ENDPOINT_URL=:4566` en estos tests: `conftest` hace unset. phpinfo no es obligatorio; `/health` sí.
