data "aws_ami" "jfrog-ami" {
    executable_users = [ "self" ]
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