# app/

Baseline Terraform del libro **Building Resilient Architectures on AWS** (Packt):

https://github.com/PacktPublishing/Building-Resilient-Architectures-on-AWS

VPC pública + EC2 Amazon Linux 2 + `user-data.sh` (LAMP y `phpinfo.php`). Adaptación: tag `Name = poc-cloud-foundation`.

**No es el stack del curso.** Apunta a AWS real (`eu-west-1`). No corras `terraform apply` acá: genera costo (t3.nano + IPv4) y deja el puerto 80 abierto a `0.0.0.0/0`.

El apply local es [`iac/local`](../iac/local). Ese stack **referencia** `user-data.sh` (ADR 003) pero LocalStack Community no lo ejecuta (ADR 004).
