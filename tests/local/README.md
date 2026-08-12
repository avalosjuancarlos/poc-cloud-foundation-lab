# `tests/local/` — pytest del stack LocalStack

Correr **dentro del devcontainer**, no en el host. Ahí están `pytest`, boto3 y `AWS_ENDPOINT_URL=http://localhost:4566` (mismo Compose que publica LocalStack).

```bash
# terminal del devcontainer (después de rebuild)
python3 -m pytest
```

- Políticas IAM: siempre (JSON / templates renderizados).
- Smoke boto3: se salta si LocalStack no está healthy. Compose lo levanta; **no aplica** Terraform.
- No hay test de HTTP/phpinfo (ADR 004).

## Si el smoke falla

Mensajes típicos cuando LocalStack está up pero `iac/local` no se aplicó:

- `no hay VPC con Project=poc-cloud-foundation-lab`
- `no hay instancia running/pending`
- `Role poc-cloud-foundation-lab-ec2 not found`

No es un bug del test: el control plane está vacío. Aplicá el stack y volvé a correr pytest:

```bash
./scripts/local/02_apply.sh   # 01_up + terraform apply en iac/local
python3 -m pytest
```
