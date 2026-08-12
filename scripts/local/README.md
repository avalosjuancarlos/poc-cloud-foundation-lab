# `scripts/local/` — demos E2E del stack LocalStack

Idempotentes, sin secretos en el código. Credenciales dummy salen del entorno del devcontainer (`test` / `test`) o de esos mismos defaults contra `:4566`.

```bash
./scripts/local/01_up.sh       # compose up + wait health
./scripts/local/02_apply.sh    # llama a 01, luego terraform apply en iac/local
./scripts/local/03_verify.py   # boto3: VPC, EC2, rol, bucket por tag
```

Correr 02 y 03 dos veces no debe crear recursos de más ni fallar.

`03_verify.py` no hace HTTP al `public_ip` (ADR 004).
