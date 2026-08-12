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
