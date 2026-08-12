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

`network.tf`: VPC `10.0.0.0/16`, dos públicas (`10.0.0.0/24`, `10.0.1.0/24`) con IGW, dos privadas (`10.0.10.0/24`, `10.0.11.0/24`) **sin** NAT.

## 4. Datos (A5)

S3 (AES256, public access block, bucket policy con Deny TLS) + IAM instance profile desde `iam/aws`. RDS PostgreSQL `db.t4g.micro`, 20 GB gp3, Single-AZ, **sin** `publicly_accessible`. Password con `random_password` (state, no git). SG de RDS solo admite 5432 desde el SG de la app; el ingress HTTP del app SG lo agrega A6.

`db_multi_az = true` está en variables; no es el default (ADR 008).

## 5. Cómputo (A6)

ALB público (HTTP 80) + ASG `t3.nano` desired 1 / max 2 en subnets públicas. SG de instancias solo desde el SG del ALB. IMDSv2 obligatorio. Sin key pair. User-data propio (`user-data.sh`): httpd + phpinfo + `/health`; **no** copia `app/user-data.sh` (ese instala MariaDB en la VM).

Éxito: `http://<alb_dns_name>/health` y `/phpinfo.php`. Destroy el mismo día (ADR 010).

## 6. Backend del stack de aplicación

Cuando existan red/RDS/ALB (A4–A6):

```bash
cp iac/aws/backend.tf.example iac/aws/backend.tf
# reemplazá ACCOUNT_ID con el output account_id del bootstrap
terraform -chdir=iac/aws init
```

`terraform.tfvars` y `backend.tf` no se commitean (gitignore).

## 7. Infracost

Solo `--path iac/aws` (ADR 011), después de A6. Nunca sobre `iac/local` ni sobre `bootstrap` como si fuera el lab de 8 h (el Budget y el state bucket sí tienen costo mínimo).
