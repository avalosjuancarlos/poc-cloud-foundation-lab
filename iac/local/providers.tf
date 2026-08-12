# Solo LocalStack. No hay perfil AWS real en este directorio (ADR 001 / 004).

provider "aws" {
  region = var.region

  access_key = "test"
  secret_key = "test"

  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_region_validation      = true

  endpoints {
    s3  = var.localstack_endpoint
    iam = var.localstack_endpoint
    sts = var.localstack_endpoint
    ec2 = var.localstack_endpoint
  }

  default_tags {
    tags = local.tags
  }
}
