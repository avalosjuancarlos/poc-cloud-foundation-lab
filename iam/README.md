# `iam/` — políticas y trust documents del proyecto

JSON versionados por stack (ADR 001 / 002). Terraform no es la fuente de las policies: las referencia.

- **`local/`** — LocalStack
- **`aws/`** — AWS real (`us-east-1`; incluye Deny TLS en el bucket)

Tipos de documento:

- **Trust policies** — quién puede asumir un rol (ej. EC2)
- **Identity policies** — qué puede hacer esa identidad (privilegio mínimo)
- **Resource policies** — qué identidades deja entrar un recurso (bucket policy)

Referencias en el lab del curso:
- Lab 04 — `iam/s3_read_policy.json` muestra una identity policy de privilegio mínimo
- Lab 06 — `s3/bucket_policy.json` muestra una resource policy con Principal=rol
