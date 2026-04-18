variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "az" {
  description = "Availabilty zones for servers"
  type = list(string)
  default = ["ap-south-1a", "ap-south-1c"]
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = list(string)
  default     = ["10.100.0.0/23"]
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnets"
  type = list(string)
  default = [ "10.100.0.0/26", "10.100.0.64/26" ]
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnets"
  type = list(string)
  default = [ "10.100.0.128/26", "10.100.0.192/26" ]
}

variable "lt_name" {
  description = "EC2 Launch Template Name"
  type = string
  default = "jfrog-lt"
}

variable "lt_ebs_volume" {
  description = "Size of ebs volume"
  type = number
  default = 30
}

variable "rds_endpoint" {
  description = "RDS DB Endpoint"
  type = string
  sensitive = true
  default = "db.sql"
}

variable "db_username" {
  description = "RDS DB UserName"
  type = string
  sensitive = true
  default = "artifactory"
}

variable "db_password" {
  description = "RDS DB Password"
  type = string
  sensitive = true
  default = "valxYklaurfue"
}