# Decision log

Registro de decisiones de arquitectura del proyecto.

## Formato (ADR)

```text
### NNN — Título corto de la decisión

Decision: qué decidiste hacer.
Contexto: qué te llevó a esta decisión.
Alternativas: qué otras opciones consideraste.
Tradeoff: qué ganás y qué cedés.
Resultado: qué quedó implementado.
```

## Decisiones

### 001 — Dos stacks independientes, no un stack parametrizado

Decision: LocalStack y AWS real son dos infraestructuras distintas, en carpetas hermanas (`iac/local` vs `iac/aws`, y lo mismo en `iam/`, `scripts/`, `tests/`). No se comparten módulos Terraform ni un `use_localstack` / tfvars que “encienda” un provider u otro.

Contexto: El baseline Packt en `app/` asume AWS real (AMI de marketplace, EC2 que ejecuta user-data LAMP). LocalStack Community emula la API de EC2/IAM/S3, no una VM. La etapa AWS real va a ser otra topología (resiliencia: más AZ, datos separados, etc.). Parametrizar un único `main.tf` acoplaría dos diseños que van a divergir.

Alternativas:
1. Un módulo compartido + `terraform.tfvars` por entorno.
2. Workspaces de Terraform (`local` / `aws`).
3. LocalStack Pro para acercar el runtime de EC2 al de AWS (pago, fuera de alcance).

Tradeoff: Se duplican carpetas y hay que mantener dos árboles. A cambio, un `apply` en `iac/local` no puede pegarle a AWS real, y `iac/aws` no queda atado a los límites de Community.

Resultado: Decisión documentada. Esta etapa implementa solo `*/local`. `*/aws` queda fuera de alcance hasta la migración.

### 002 — El proyecto se agrupa por entorno bajo las carpetas del starter

Decision: Dentro de `iac/`, `iam/`, `scripts/` y `tests/` hay un subárbol `local/` (etapa 1) y más adelante `aws/`. `compose.yaml` queda en la raíz porque el devcontainer lo espera ahí y solo aplica al entorno local. `docs/`, `app/` y `.devcontainer/` no se duplican.

Contexto: El checklist del README exige esas rutas en la raíz (`iam/`, `scripts/`, `compose.yaml`). Agrupar “todo el entorno” en `environments/localstack/` rompería el contrato del curso. Agrupar *dentro* de cada carpeta del starter cumple el checklist y mantiene la separación de stacks (ADR 001).

Alternativas:
1. `environments/localstack/{iac,iam,scripts}` — más claro, pero el checklist y el `postStartCommand` del devcontainer apuntan a la raíz.
2. Dejar IAM y scripts compartidos y separar solo Terraform.

Tradeoff: Un nivel más de carpetas. El README E2E tiene que decir `scripts/local/...` y `terraform -chdir=iac/local`.

Resultado: Decisión documentada. Las carpetas `*/local` se crean en las tareas de implementación (IAM, IaC, scripts, tests), no en este ADR.

### 003 — `app/` es el baseline Packt, no el stack que se aplica

Decision: `app/main.tf` y `app/user-data.sh` se conservan como origen del libro *Building Resilient Architectures on AWS*. El apply del curso no se corre desde `app/`. `iac/local` puede *referenciar* `app/user-data.sh` para no duplicar el bootstrap; no reescribe el sample para LocalStack.

Contexto: El código de `app/` forma parte de https://github.com/PacktPublishing/Building-Resilient-Architectures-on-AWS. Mezclar adaptaciones LocalStack ahí borra la trazabilidad del libro y deja un provider AWS real (`eu-west-1`) al lado de comandos de apply, con riesgo FinOps.

Alternativas:
1. Convertir `app/main.tf` en el stack LocalStack.
2. Copiar user-data a `iac/local/` y olvidar `app/` para el apply.
3. Borrar `app/` una vez portado.

Tradeoff: Dos árboles Terraform visibles (`app/` vs `iac/local`). Queda explícito qué es el libro y qué es el lab.

Resultado: `app/README.md` ya cita Packt y aclara que no está cableado a LocalStack. El apply canónico será `iac/local` cuando exista.

### 004 — Etapa 1: criterio de éxito solo contra LocalStack Community

Decision: Listo significa: LocalStack healthy en Compose, `terraform apply` en `iac/local` crea VPC, security group, instance, rol y bucket, y `scripts/local` + tests lo verifican vía API en `localhost:4566`. No es criterio de éxito abrir `phpinfo.php` ni comprobar que user-data corrió.

Contexto: Community no arranca Amazon Linux ni ejecuta `user-data.sh`. El data source de AMI del sample Packt no resuelve `amzn2-ami-hvm-2.0*` contra el emulador. Exigir el LAMP en local empujaría a Pro o a AWS real en la etapa 1.

Alternativas:
1. Contenedor `httpd/php` en Compose como “equivalente de cómputo” (demo de app, no de `aws_instance`).
2. LocalStack Pro.
3. Apply a AWS real desde el día uno.

Tradeoff: Se valida el contrato de IaC/IAM/S3 a nivel API, no el runtime LAMP. Eso se pospone a `*/aws`.

Resultado: Decisión documentada. AMI dummy (`ami-12345678` o equivalente) y región `us-east-1` en `iac/local`. Output de IP pública no se documenta como URL navegable.

### 005 — IAM y scripts son artefactos del stack local (checklist del README)

Decision: Las políticas de esta etapa viven en `iam/local/` (trust de EC2, identity policy de privilegio mínimo, bucket policy). La ejecución E2E vive en `scripts/local/` con al menos tres demos idempotentes, sin secretos hardcodeados. Terraform en `iac/local` consume los JSON con `file()` / `templatefile()`, no define las policies solo inline.

Contexto: El README exige `iam/` con trust + policies + bucket policy, y `scripts/` con ≥3 demos. El sample Packt no trae instance profile ni S3; el entregable ITBA sí. Meter JSON en HCL dificulta la revisión estilo labs 04/06.

Alternativas:
1. Policies solo en recursos `aws_iam_policy` del `.tf`.
2. Un solo script `make apply`.
3. Dejar IAM para la etapa AWS.

Tradeoff: Hay que interpolar ARNs (account LocalStack `000000000000` vs cuenta real después). En Community algunas condiciones (`aws:SecureTransport`) pueden no aplicarse; se dejan igual como intención para AWS.

Resultado: Decisión documentada. Archivos concretos en las tareas P4 (IAM), P6 (scripts) y P7 (tests).
