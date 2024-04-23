

resource "aws_security_group" "lambda_sg" {
  name   = "lambda_sg"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security group for RDS PostgreSQL instance"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group_rule" "allow_lambda_to_rds" {
  type            = "ingress"
  from_port       = 5432  # PostgreSQL port, change as needed
  to_port         = 5432
  protocol        = "tcp"
  source_security_group_id = aws_security_group.lambda_sg.id
  security_group_id = aws_security_group.rds_sg.id  # ID of your RDS instance's security group
}
