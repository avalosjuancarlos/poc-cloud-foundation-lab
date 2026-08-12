# `scripts/` — demos automatizados del proyecto

Orquestación end-to-end, agrupada por stack (ADR 002 / 005).

- **`local/`** — etapa LocalStack
- **`aws/`** — etapa AWS real (`01_creds`, `infracost`, `02_apply`, `03_verify`)

Convenciones del curso:
- **Idempotentes** — se pueden correr dos veces sin romper
- **Sin secretos hardcodeados** — leen credenciales del entorno
- **Auto-documentados** — el output narra qué se hizo y dónde quedó

Referencias en el lab del curso:
- `scripts/iam_demo.py` — patrón de orquestación + idempotencia
- `scripts/ec2_demo.py` — uso de tags para detectar recursos existentes
- `scripts/s3_demo.py` — head_object para idempotencia por contenido
- `scripts/vpc_demo.py` — find-by-tag helper para grafo de recursos
