# AWS real. Sin endpoints LocalStack (ADR 009).
# Requiere: scripts/aws/01_creds.sh o AWS_PROFILE=poc-aws y AWS_ENDPOINT_URL unset.

provider "aws" {
  region  = var.region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "aws"
      ManagedBy   = "terraform"
      Component   = "bootstrap"
    }
  }
}
