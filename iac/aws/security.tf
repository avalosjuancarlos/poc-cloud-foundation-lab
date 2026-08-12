# App SG sin ingress HTTP todavía: A6 lo abre solo desde el ALB (ADR 007).
# Reglas como recursos aparte para no pelear con el SG del ALB.

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app"
  description = "ASG instances. HTTP solo desde el ALB (A6)."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-app"
  }
}

resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds"
  description = "PostgreSQL solo desde el SG de la app."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-rds"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_app" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}
