# `iac/aws/` — stack AWS real (us-east-1)

No compartir módulos con `iac/local`. No aplicar `app/`.

## 1. Profile (ADR 009)

En el **host o en el devcontainer**, un named profile (no mezclar con LocalStack):

```bash
aws configure --profile poc-aws
# region: us-east-1
```

El devcontainer exporta `AWS_ENDPOINT_URL=http://localhost:4566` y keys `test`. Antes de cualquier comando AWS real:

```bash
./scripts/aws/01_creds.sh
```

Ese script hace unset del endpoint y de las keys dummy, exporta `AWS_PROFILE=poc-aws` y llama a `sts get-caller-identity`. Si el account es `000000000000`, estás en LocalStack: aborta.

## 2. Bootstrap (state + lock + Budget)

El backend S3 no puede crearse a sí mismo. Este directorio usa **state local** a propósito:

```bash
./scripts/aws/01_creds.sh
cp iac/aws/bootstrap/terraform.tfvars.example iac/aws/bootstrap/terraform.tfvars
# editá budget_email
terraform -chdir=iac/aws/bootstrap init
terraform -chdir=iac/aws/bootstrap apply
```

Crea: bucket de state (versionado, cifrado, sin acceso público), tabla DynamoDB de lock, Budget mensual USD 5 (ADR 010) con mail al 80% actual y 100% forecast.

**No hagas destroy del bootstrap** salvo que sepas que no queda state remoto.

## 3. Red (A4)

`network.tf`: VPC `10.0.0.0/16`, dos públicas (`10.0.0.0/24`, `10.0.1.0/24`) con IGW, dos privadas (`10.0.10.0/24`, `10.0.11.0/24`) **sin** NAT. RDS (A5) y ALB/ASG (A6) usan estos outputs.

## 4. Backend del stack de aplicación

Cuando existan red/RDS/ALB (A4–A6):

```bash
cp iac/aws/backend.tf.example iac/aws/backend.tf
# reemplazá ACCOUNT_ID con el output account_id del bootstrap
terraform -chdir=iac/aws init
```

`terraform.tfvars` y `backend.tf` no se commitean (gitignore).

## 5. Infracost

Solo `--path iac/aws` (ADR 011), después de A6. Nunca sobre `iac/local` ni sobre `bootstrap` como si fuera el lab de 8 h (el Budget y el state bucket sí tienen costo mínimo).
