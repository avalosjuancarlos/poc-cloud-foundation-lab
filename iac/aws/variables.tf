variable "project_name" {
  type        = string
  description = "Slug del proyecto."
  default     = "poc-cloud-foundation-lab"
}

variable "region" {
  type        = string
  description = "Región del stack (ADR 006)."
  default     = "us-east-1"
}

variable "aws_profile" {
  type        = string
  description = "Named profile (ADR 009)."
  default     = "poc-aws"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR de la VPC."
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "Dos AZs en us-east-1 (ADR 006)."
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "Se requieren exactamente dos AZs (ADR 006)."
  }
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Subnets públicas (ALB + ASG). Mismo orden que availability_zones."
  default     = ["10.0.0.0/24", "10.0.1.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Se requieren exactamente dos CIDR públicos."
  }
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Subnets privadas (RDS). Sin NAT (ADR 007)."
  default     = ["10.0.10.0/24", "10.0.11.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Se requieren exactamente dos CIDR privados."
  }
}

variable "bucket_name" {
  type        = string
  default     = null
  description = "Bucket de la app. Si es null: {project}-{account_id}-app."
}

variable "db_instance_class" {
  type        = string
  description = "Clase RDS (ADR 008)."
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  type        = number
  description = "Storage gp3 en GiB."
  default     = 20
}

variable "db_engine_version" {
  type        = string
  description = "Major version de PostgreSQL."
  default     = "16"
}

variable "db_multi_az" {
  type        = bool
  description = "Multi-AZ duplica el costo de RDS. Default false (ADR 008)."
  default     = false
}

variable "db_name" {
  type        = string
  description = "Nombre de la base inicial."
  default     = "app"
}

variable "db_username" {
  type        = string
  description = "Master user. No usar postgres (reservado)."
  default     = "appadmin"
}

variable "instance_type" {
  type        = string
  description = "Tipo de instancia del ASG (ADR 010)."
  default     = "t3.nano"
}

variable "asg_min_size" {
  type        = number
  description = "Mínimo del ASG."
  default     = 1
}

variable "asg_max_size" {
  type        = number
  description = "Máximo del ASG (ADR 010)."
  default     = 2
}

variable "asg_desired_capacity" {
  type        = number
  description = "Desired del ASG. 1 para el lab (ADR 010)."
  default     = 1

  validation {
    condition     = var.asg_desired_capacity >= 1 && var.asg_desired_capacity <= 2
    error_message = "desired_capacity del lab debe estar entre 1 y 2 (ADR 010)."
  }
}
