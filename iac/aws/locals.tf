data "aws_caller_identity" "current" {}

locals {
  bucket_name = coalesce(var.bucket_name, "${var.project_name}-${data.aws_caller_identity.current.account_id}-app")
}
