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