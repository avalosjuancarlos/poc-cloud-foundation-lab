# Cómputo emulado. user-data se declara (origen Packt) y no se ejecuta en Community.

resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main.id
  iam_instance_profile   = aws_iam_instance_profile.app.name
  vpc_security_group_ids = [aws_security_group.allow_http.id]
  user_data              = file("${path.module}/../../app/user-data.sh")

  depends_on = [aws_iam_role_policy_attachment.app]

  tags = {
    Name = "${var.project_name}-web"
  }
}
