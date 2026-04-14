## security group
resource "aws_security_group" "gp-lt-sg" {
  name        = "gp-lt-sg"
  description = "Security group for jfrog launch template"
  vpc_id      = aws_vpc.gp-jfrog-vpc.id

  tags = {
    Name = "gp-lt-sg"
  }
}

resource "aws_security_group_rule" "jfrog_ingress_private" {
  type              = "ingress"
  from_port         = 8082
  to_port           = 8082
  protocol          = "tcp"
  cidr_blocks       = "0.0.0.0/0"
  security_group_id = aws_security_group.gp-lt-sg.id
}

# Allow egress everywhere (for RDS to reach S3, KMS, etc.)
resource "aws_security_group_rule" "jfrog_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.gp-lt-sg.id
}

resource "aws_launch_template" "gp-lt" {
    name = var.lt_name

    block_device_mappings {
      device_name = "/dev/sda1"

      ebs {
        volume_size = var.lt_ebs_volume
      }
    }

    capacity_reservation_specification {
      capacity_reservation_preference = "none"
    }

    ebs_optimized = true

    image_id = "ami-0c6ec6ccdd6dc6a98"

    instance_initiated_shutdown_behavior = "terminate"

    instance_market_options {
      market_type = "spot"
    }

    instance_type = "t2.large"

    key_name = "jfrog_vm"

    metadata_options {
      http_endpoint = "enabled"
      http_tokens = "required"
      http_put_response_hop_limit = 1
      instance_metadata_tags = "enabled"
    }

    network_performance_options {
      bandwidth_weighting = "vpc-1"
    }

    network_interfaces {
      associate_public_ip_address = false
      delete_on_termination = true
    }

    placement {
      availability_zone = "ap-south-1"
    }

    vpc_security_group_ids = [ aws_security_group.gp-lt-sg.id ]

    tags = {
        Name = "gp-jfrog-lt"
    }

    user_data = filebase64()
}