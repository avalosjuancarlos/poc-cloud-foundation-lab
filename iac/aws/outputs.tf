output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC del stack aws."
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "Subnets públicas (ALB + ASG), una por AZ."
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "Subnets privadas (RDS). Sin ruta a Internet."
}

output "availability_zones" {
  value       = var.availability_zones
  description = "AZs usadas."
}

output "bucket_name" {
  value       = aws_s3_bucket.app.bucket
  description = "Bucket de la app (TLS deny en la bucket policy)."
}

output "role_arn" {
  value       = aws_iam_role.app.arn
  description = "Rol de instancia (Principal de la bucket policy)."
}

output "instance_profile_name" {
  value       = aws_iam_instance_profile.app.name
  description = "Instance profile para el ASG (A6)."
}

output "app_security_group_id" {
  value       = aws_security_group.app.id
  description = "SG de las instancias. A6 agrega ingress desde el ALB."
}

output "rds_endpoint" {
  value       = aws_db_instance.app.address
  description = "Hostname privado de PostgreSQL."
}

output "rds_port" {
  value       = aws_db_instance.app.port
  description = "Puerto PostgreSQL."
}

output "db_name" {
  value       = aws_db_instance.app.db_name
  description = "Base inicial."
}

output "db_username" {
  value       = aws_db_instance.app.username
  description = "Master user."
}

output "db_password" {
  value       = random_password.db.result
  sensitive   = true
  description = "Password generado. Vive en el state, no en git."
}
