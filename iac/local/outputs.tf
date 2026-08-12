output "instance_id" {
  value       = aws_instance.web.id
  description = "ID de la instancia en LocalStack."
}

output "public_ip" {
  value       = aws_instance.web.public_ip
  description = "IP emulada. No es un HTTP real; phpinfo no es criterio de éxito (ADR 004)."
}

output "bucket_name" {
  value       = aws_s3_bucket.app.bucket
  description = "Bucket S3 emulado."
}

output "role_arn" {
  value       = aws_iam_role.app.arn
  description = "Rol de instancia (Principal de la bucket policy)."
}
