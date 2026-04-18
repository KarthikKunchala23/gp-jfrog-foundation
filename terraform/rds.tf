resource "aws_db_subnet_group" "jfrog-db-subnet-group" {
  name       = "jfrog-db-subnet-group"
  subnet_ids = aws_subnet.gp-jfrog-pgsql-subnet.id

  tags = {
    Name = "jfrog-db-subnet-group"
  }
}

resource "aws_security_group" "jfrog-rds-sg" {
  name        = "jfrog-rds-sg"
  description = "Allow JFrog EC2 to access RDS"
  vpc_id      = aws_vpc.gp-jfrog-vpc.id

  tags = {
    Name = "jfrog-rds-sg"
  }
}

resource "aws_security_group_rule" "rds_ingress_jfrog" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.jfrog-rds-sg.id
  source_security_group_id = aws_security_group.gp-lt-sg.id
}

resource "aws_security_group_rule" "rds_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jfrog-rds-sg.id
}

resource "aws_db_instance" "jfrog-postgres" {
  identifier              = "jfrog-postgres-dev"
  engine                  = "postgres"
  engine_version          = "14"
  instance_class          = "db.t3.micro"

  allocated_storage       = 20
  max_allocated_storage   = 100
  storage_type            = "gp2"

  db_subnet_group_name    = aws_db_subnet_group.jfrog-db-subnet-group.name
  vpc_security_group_ids  = [aws_security_group.jfrog-rds-sg.id]

  multi_az                = false   # change to true for prod
  publicly_accessible     = false

  skip_final_snapshot     = true    # change in prod
  deletion_protection     = false

  backup_retention_period = 7

  tags = {
    Name = "jfrog-postgres"
  }
}