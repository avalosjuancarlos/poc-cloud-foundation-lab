# `scripts/aws/` — demos del stack AWS real

Idempotentes, sin secretos en git. Profile `poc-aws` (ADR 009). Correr en el **host** (Infracost y named profile); si usás el devcontainer, `01_creds` saca el overlay LocalStack.

```bash
./scripts/aws/01_creds.sh     # unset LocalStack + sts get-caller-identity
./scripts/aws/infracost.sh    # scan iac/aws (no aplica)
./scripts/aws/02_apply.sh     # infracost + plan + confirmación + apply
./scripts/aws/03_verify.py    # API + HTTP /health en el ALB
```

`02_apply` **no** usa `-auto-approve`. Sin TTY: `CONFIRM_APPLY=yes`. Para saltear Infracost: `SKIP_INFRACOST=1` (no recomendado).

Antes del primer apply:

```bash
cp iac/aws/backend.tf.example iac/aws/backend.tf
cp iac/aws/terraform.tfvars.example iac/aws/terraform.tfvars
# ACCOUNT_ID en backend.tf = output account_id del bootstrap
```

Destroy el mismo día:

```bash
terraform -chdir=iac/aws destroy
```

`03_verify.py` aborta si la cuenta es `000000000000` (LocalStack). phpinfo es extra; `/health` es el criterio.
