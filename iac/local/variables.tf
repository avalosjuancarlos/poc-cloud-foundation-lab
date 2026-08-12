variable "project_name" {
  type        = string
  description = "Slug del proyecto. Se usa para nombrar recursos."
  default     = "poc-cloud-foundation-lab"
}

variable "environment" {
  type        = string
  description = "Entorno de este stack. Fijo en local."
  default     = "local"
}

variable "region" {
  type        = string
  description = "Región emulada por LocalStack."
  default     = "us-east-1"
}

variable "availability_zone" {
  type        = string
  description = "AZ emulada. Community no replica fallos de AZ."
  default     = "us-east-1a"
}

variable "localstack_endpoint" {
  type        = string
  description = "Gateway de LocalStack. Nunca un endpoint de AWS real."
  default     = "http://localhost:4566"
}

variable "ami_id" {
  type        = string
  description = "AMI dummy. Community no resuelve Amazon Linux 2 (ADR 004)."
  default     = "ami-12345678"
}

variable "instance_type" {
  type        = string
  description = "Tipo de instancia. t3.nano: barato si alguien aplica esto mal a AWS."
  default     = "t3.nano"
}

variable "bucket_name" {
  type        = string
  description = "Nombre del bucket S3 del proyecto."
  default     = "poc-cloud-foundation-lab-data"
}
