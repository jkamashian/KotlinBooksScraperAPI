// Database setup

resource "aws_db_instance" "librarian" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "15.4"
  instance_class       = "db.t3.micro"
  identifier           = var.identifier
  username             = var.db_username
  password             = var.db_password
  storage_type         = "gp2"
  db_name = var.db_name
  # Networking and security
  db_subnet_group_name = aws_db_subnet_group.aws_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = true

  skip_final_snapshot = true
}


resource "null_resource" "db_setup" {

  depends_on = [aws_db_instance.librarian, aws_security_group.rds_sg]
  provisioner "local-exec" {
    command = "psql -h ${aws_db_instance.librarian.address} -U ${var.db_username} -d ${var.db_name} -f ../DB/init.sql"
    environment = {
      PGPASSWORD = var.db_password
    }
  }
}

resource "aws_db_subnet_group" "aws_db_subnet_group" {
  name       = "main-db-subnet-group"
  subnet_ids = concat([aws_subnet.private_1.id, aws_subnet.private_2.id], var.subnets)
  tags = {
    Name = "My DB Subnet Group"
  }
}





