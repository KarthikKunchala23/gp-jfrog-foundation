variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = list(string)
  default     = ["10.100.1.0/23"]
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnets"
  type = list(string)
  default = [ "10.100.1.0/26", "10.100.1.64/26" ]
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnets"
  type = list(string)
  default = [ "10.100.1.128/26", "10.100.1.192/26" ]
}