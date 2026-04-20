data "aws_ami" "jfrog-ami" {
    owners = [ "self" ]
    most_recent = true
    
    filter {
      name = "name"
      values = ["jfrog-ubuntu"]
    }

    filter {
      name = "virtualization-type"
      values = ["hvm"]
    }

    filter {
      name = "root-device-type"
      values = ["ebs"]
    }
}

data "aws_iam_role" "serviceroleasg" {
    name = "AWSServiceRoleForAutoScaling"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_iam_role" "bastion_rds" {
  name = "bastionrds"
}