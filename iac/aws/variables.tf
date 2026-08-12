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
