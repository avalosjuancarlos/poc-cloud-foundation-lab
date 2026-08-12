# `tests/local/` — pytest del stack LocalStack

Correr **dentro del devcontainer**, no en el host. Ahí están `pytest`, boto3 y `AWS_ENDPOINT_URL=http://localhost:4566` (mismo Compose que publica LocalStack).

```bash
# terminal del devcontainer (después de rebuild)
python3 -m pytest
```

- Políticas IAM: siempre (JSON / templates renderizados).
- Smoke boto3: se salta si LocalStack no está healthy; primero `./scripts/local/01_up.sh` y `./scripts/local/02_apply.sh`.
- No hay test de HTTP/phpinfo (ADR 004).
