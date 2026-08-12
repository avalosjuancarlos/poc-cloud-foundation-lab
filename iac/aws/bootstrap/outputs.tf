output "state_bucket" {
  value       = aws_s3_bucket.tfstate.bucket
  description = "Bucket para backend del stack iac/aws (no destruir a la ligera)."
}

output "lock_table" {
  value       = aws_dynamodb_table.tf_lock.name
  description = "Tabla DynamoDB de lock."
}

output "account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "Debe ser tu cuenta real, no 000000000000."
}
