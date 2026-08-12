# PostgreSQL fuera de la EC2 (ADR 008). Single-AZ por default. Sin IP pública.

resource "random_password" "db" {
  length  = 24
  special = false
}

resource "aws_db_subnet_group" "app" {
  name       = "${var.project_name}-rds"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-rds"
  }
}

resource "aws_db_instance" "app" {
  identifier     = "${var.project_name}-pg"
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.app.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = var.db_multi_az

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true

  performance_insights_enabled = false
  auto_minor_version_upgrade   = true

  tags = {
    Name = "${var.project_name}-pg"
  }
}
