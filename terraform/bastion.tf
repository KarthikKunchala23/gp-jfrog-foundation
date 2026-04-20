resource "aws_instance" "gp-jfrog-bastion" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "t3.micro"
    subnet_id = aws_subnet.gp-jfrog-public-subnet[0].id
    associate_public_ip_address = true
    vpc_security_group_ids = [ aws_security_group.gp-jfrog-bastion-sg.id ]
    iam_instance_profile = data.aws_iam_role.bastion_rds.name
    key_name = "jfrog_vm"

    tags = {
      Name = "Bastion"
    } 
}


