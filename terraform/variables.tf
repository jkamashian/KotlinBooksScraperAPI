variable "db_name" {
  type = string
  sensitive = true
}
variable "db_username" {
  type = string
  sensitive = true
}
variable "db_password" {
  type = string
  sensitive = true
}
variable "identifier" {
  type = string
  sensitive = true
}
variable "subnets" {
  type = list(string)
  description = "A list of subnet IDs for deploying resources"
  sensitive = true
}

variable "vpc_cidr" {
  type = string
  description = "cidr block for the vpc"
}

variable "vpc_id" {
  type = string
  description = "cidr block for the vpc"
}

variable "aws_route_table_public_cidr" {
  type = string
}
variable "aws_subnet_public_cidr" {
  type = string
}
variable "aws_route_table_private_cidr" {
  type = string
}
variable "aws_subnet_private_1_cidr" {
  type = string
}
variable "aws_subnet_private_2_cidr" {
  type = string
}
variable "scraper_file_path" {
  type = string
}

variable "get_file_path" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "lambda_sg_egress_cidr" {
  type = string
}
variable "rds_sg_ingress_cidr" {
    type = string
}
variable "rds_sg_egress_cidr" {
  type = string
}
