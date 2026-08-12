variable "project_name" {
  type        = string
  description = "Slug del proyecto."
  default     = "poc-cloud-foundation-lab"
}

variable "region" {
  type        = string
  description = "Región del backend y del Budget (ADR 006)."
  default     = "us-east-1"
}

variable "aws_profile" {
  type        = string
  description = "Named profile. No uses default si el default es LocalStack."
  default     = "poc-aws"
}

variable "budget_email" {
  type        = string
  description = "Mail para alertas del Budget (ADR 010). Obligatorio en tfvars."
}

variable "budget_limit_usd" {
  type        = string
  description = "Tope mensual en USD."
  default     = "5"
}
