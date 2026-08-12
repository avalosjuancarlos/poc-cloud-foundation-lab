resource "aws_s3_bucket" "app" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_policy" "app" {
  bucket = aws_s3_bucket.app.id
  policy = templatefile("${path.module}/../../iam/local/bucket_policy.json.tftpl", {
    bucket_name = aws_s3_bucket.app.bucket
    role_arn    = aws_iam_role.app.arn
  })
}
