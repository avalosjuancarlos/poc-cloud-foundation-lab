# Stack de aplicación AWS. Sin endpoints LocalStack (ADR 009).
# Copiá backend.tf.example → backend.tf después del bootstrap y rellená bucket/table.

provider "aws" {
  region  = var.region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "aws"
      ManagedBy   = "terraform"
    }
  }
}
