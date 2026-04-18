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