# Bucket de la app. force_destroy para el apply efímero (ADR 010).

resource "aws_s3_bucket" "app" {
  bucket        = local.bucket_name
  force_destroy = true

  tags = {
    Name = local.bucket_name
  }
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "app" {
  bucket = aws_s3_bucket.app.id
  policy = templatefile("${path.module}/../../iam/aws/bucket_policy.json.tftpl", {
    bucket_name = aws_s3_bucket.app.bucket
    role_arn    = aws_iam_role.app.arn
  })

  depends_on = [aws_s3_bucket_public_access_block.app]
}
