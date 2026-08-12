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
