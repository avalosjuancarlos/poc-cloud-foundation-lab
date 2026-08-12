# `scripts/aws/` — demos del stack AWS real

Idempotentes, sin secretos en git. Profile `poc-aws` (ADR 009).

```bash
./scripts/aws/01_creds.sh    # unset LocalStack + sts get-caller-identity
# 02_apply y 03_verify: A8
```

`01_creds.sh` se puede correr dos veces: solo verifica identidad.
