# Identidad: JSON en iam/local (ADR 005). La EC2 no lleva access keys.

resource "aws_iam_role" "app" {
  name               = "${var.project_name}-ec2"
  assume_role_policy = file("${path.module}/../../iam/local/trust_policy.json")
}

resource "aws_iam_policy" "app" {
  name = "${var.project_name}-ec2-app"
  policy = templatefile("${path.module}/../../iam/local/ec2_app_policy.json.tftpl", {
    bucket_name = aws_s3_bucket.app.bucket
  })
}

resource "aws_iam_role_policy_attachment" "app" {
  role       = aws_iam_role.app.name
  policy_arn = aws_iam_policy.app.arn
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.project_name}-ec2"
  role = aws_iam_role.app.name
}
