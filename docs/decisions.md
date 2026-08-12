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

Resultado: `*/local` implementado (P1–P9). `*/aws` se implementa en esta etapa (A1–A10); no comparte módulos con local.

### 002 — El proyecto se agrupa por entorno bajo las carpetas del starter

Decision: Dentro de `iac/`, `iam/`, `scripts/` y `tests/` hay un subárbol `local/` (etapa 1) y más adelante `aws/`. `compose.yaml` queda en la raíz porque el devcontainer lo espera ahí y solo aplica al entorno local. `docs/`, `app/` y `.devcontainer/` no se duplican.

Contexto: El checklist del README exige esas rutas en la raíz (`iam/`, `scripts/`, `compose.yaml`). Agrupar “todo el entorno” en `environments/localstack/` rompería el contrato del curso. Agrupar *dentro* de cada carpeta del starter cumple el checklist y mantiene la separación de stacks (ADR 001).

Alternativas:
1. `environments/localstack/{iac,iam,scripts}` — más claro, pero el checklist y el `postStartCommand` del devcontainer apuntan a la raíz.
2. Dejar IAM y scripts compartidos y separar solo Terraform.

Tradeoff: Un nivel más de carpetas. El README E2E tiene que decir `scripts/local/...` y `terraform -chdir=iac/local`.

Resultado: `iam/local`, `scripts/local` y `tests/local` existen. `*/aws` se agrega en A3/A8/A9.

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

Resultado: Decisión documentada. Archivos concretos en P4 (IAM), P6 (scripts) y P7 (tests). El equivalente AWS vive en `iam/aws` y `scripts/aws` (ADR 002).

### 006 — Región us-east-1 para el stack AWS

Decision: `iac/aws` se despliega en `us-east-1` (N. Virginia), AZs `us-east-1a` y `us-east-1b`. No se usa `eu-west-1` (sample Packt) ni `sa-east-1` (São Paulo).

Contexto: El lab se opera desde Argentina unas pocas horas. FinOps: `t3.nano` on-demand ≈ USD 0.0052/h en us-east-1 vs ≈ 0.0084 en sa-east-1 y ≈ 0.0057 en eu-west-1. DevOps: us-east-1 tiene más AZs, más tipos de instancia, AWS Academy y ejemplos de Terraform. sa-east-1 mejora RTT al Cono Sur, irrelevante si no hay usuarios productivos en LATAM.

Alternativas:
1. sa-east-1 — menor latencia, ~60% más caro en nano; menos AZs.
2. eu-west-1 — fidelidad al libro Packt; no es la región más barata ni la de Academy.
3. us-east-2 / us-west-2 — precio similar a N. Virginia; menos “default” en docs.

Tradeoff: Más latencia que São Paulo. A cambio: costo mínimo, 6 AZs, mejor soporte de APIs.

Resultado: Documentado. El provider y las subnets de `iac/aws` (A4) deben fijar esta región.

### 007 — Sin NAT Gateway; app pública detrás de ALB, RDS privada

Decision: Las instancias del ASG viven en subnets **públicas** (egress por Internet Gateway, user-data/yum). RDS en subnets **privadas** sin `publicly_accessible`. El security group de las EC2 solo admite tráfico del SG del ALB (no `0.0.0.0/0:80` en la instancia). No se crea NAT Gateway ni NAT instance.

Contexto: Un NAT Gateway en us-east-1 ronda USD 32/mes + data processing, más que el resto del lab junto. Las EC2 en subnet pública pueden llegar a RDS por ruteo VPC (IP privada) sin NAT. El ALB es el único origen HTTP.

Alternativas:
1. Private subnet + NAT GW — modelo “fortaleza”; costo inaceptable en lab.
2. NAT instance t3.nano — más barato, más operativo y otro SPOF.
3. Egress-only IPv6 — complejidad fuera de alcance.

Tradeoff: Las EC2 tienen IP pública (hay que cobrar IPv4 y endurecer SG/IMDSv2). Se evita el cargo fijo del NAT.

Resultado: Implementado. Red en A4; ALB+ASG en A6 (`alb.tf`, `compute.tf`). IMDSv2 required; sin puerto 22.

### 008 — RDS PostgreSQL db.t4g.micro Single-AZ

Decision: El estado deja de vivir en la EC2 (MariaDB del user-data Packt). Base: Amazon RDS PostgreSQL `db.t4g.micro`, 20 GB gp3, `multi_az = false` por default. Variable documentada para Multi-AZ; no es el default del lab.

Contexto: El checklist del curso apunta al lab 08 (RDS). Colocar la DB en la misma VM es el SPOF que el libro de resiliencia quiere romper. Multi-AZ duplica el costo de RDS. Graviton (`t4g`) es más barato que `db.t3.micro` en us-east-1.

Alternativas:
1. MariaDB/MySQL en la EC2 — fiel a Packt; peor resiliencia y FinOps.
2. RDS Multi-AZ de entrada — mejor RTO/RPO; ~2× precio.
3. Aurora Serverless v2 — overkill y factura menos predecible para un lab de 8 h.

Tradeoff: Single-AZ sigue siendo SPOF de AZ para datos. Sigue siendo mejor que DB en el compute. El apply efímero (ADR 010) limita la ventana de riesgo.

Resultado: Implementado en `iac/aws` (`rds.tf`). Multi-AZ queda como variable, default `false`.

### 009 — Profile `poc-aws`; no mezclar con LocalStack

Decision: El apply AWS usa un named profile (`poc-aws`), `tfvars` no commiteados (solo `.example`), y backend S3 + DynamoDB lock en us-east-1. Los scripts `scripts/aws` hacen `unset AWS_ENDPOINT_URL` (y no usan keys `test`). Nunca `terraform apply` desde `app/`.

Contexto: El devcontainer exporta `AWS_ENDPOINT_URL=http://localhost:4566` y credenciales dummy para LocalStack. boto3/AWS CLI respetan esa variable: un verify AWS sin unset pega al emulador. Keys en git o profile `default` mezclado son el incidente FinOps/DevSecOps típico.

Alternativas:
1. Un segundo devcontainer solo AWS — más aislamiento, más fricción.
2. OIDC/IAM Identity Center desde el día uno — correcto en prod; para el lab un profile alcanza.
3. Credenciales en `terraform.tfvars` commiteado — prohibido.

Tradeoff: Hay que configurar el profile a mano una vez. A cambio, local y aws no se pisan.

Resultado: Implementado. Guardrails en A2; `scripts/aws/01_creds.sh`, `02_apply.sh` y `03_verify.py` en A8.

### 010 — Apply efímero y Budget

Decision: ASG `desired_capacity = 1` (max 2). El runbook es apply → demo → `terraform destroy` el mismo día. Alarma AWS Budget (orden USD 5) al mail del grupo. Tags `Project`, `Environment=aws`, `ManagedBy=terraform`.

Contexto: ALB + RDS + IPv4 olvidados 30 días ≈ USD 36–40. El lab no necesita HA 24/7. Infracost da el mensual; el Budget cubre el olvido.

Alternativas:
1. Dejar el stack prendido “para la defensa” — costo y superficie.
2. Instance Scheduler / stop nocturno — extra IaC; destroy es más simple.
3. Savings Plans — no cierran en un lab de horas.

Tradeoff: No hay resiliencia continua. Hay control de factura.

Resultado: Documentado. Runbook en A10; Budget en A2.

### 011 — Infracost cotiza `iac/aws`, no `iac/local`

Decision: La fuente de [costs-aws.md](./costs-aws.md) es `infracost scan` (CLI v2; `breakdown` es alias) con config `infracost.yml` y usage `iac/aws/infracost-usage.yml`. Prohibido usar Infracost sobre `iac/local`: Community no factura y el HCL se cotizaría como AWS real. Login/`INFRACOST_API_KEY` solo en el host. A las ~48 h de un apply, contrastar con Cost Explorer. `02_apply` muestra el breakdown y pide confirmación antes de aplicar.

Contexto: Infracost lee el HCL y la price list; es reproducible y atado a *este* diseño. Buscar precios online sirvió para elegir región (ADR 006) antes de existir `iac/aws`. LCU del ALB y data transfer requieren usage file o quedan subestimados. Free tier y descuentos de cuenta no aparecen.

Alternativas:
1. Solo calculadora AWS a mano — se desactualiza al cambiar el `.tf`.
2. Solo Cost Explorer — es *después* del gasto.
3. Cotizar también `iac/local` — confunde USD 0 local con EC2 real.

Tradeoff: Estimación, no factura. Hay que mantener `infracost.yml` y `infracost-usage.yml`.

Resultado: Ejecutado en A7 con Infracost v2.16.1 del host (`infracost scan` → USD 34.88 / 30 d, con LCU y S3 desde usage). Config `infracost.yml` (solo `iac/aws`); usage en `iac/aws/infracost-usage.yml`. IPv4 autoasignado se documenta a mano. `02_apply` (A8) reutiliza el script.
