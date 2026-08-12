# `tests/` — pruebas del proyecto

Agrupadas por stack (ADR 002).

```bash
python3 -m pytest
```

- **`local/`** — IAM JSON; smoke boto3 si LocalStack está up (devcontainer)
- **`aws/`** — IAM JSON de `iam/aws` (TLS deny); smoke skip sin profile `poc-aws`

El smoke aws no debe correr contra LocalStack. Ver [local/README.md](./local/README.md) y [aws/README.md](./aws/README.md).
