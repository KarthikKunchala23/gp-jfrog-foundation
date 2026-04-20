resource "aws_iam_role" "jfrog_ec2_role" {
  name = "jfrog-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3" {
  role       = aws_iam_role.jfrog_ec2_role.name
  policy_arn = data.aws_iam_policy.jfrog-policy.arn
}

resource "aws_iam_instance_profile" "jfrog_profile" {
  name = "jfrog-instance-profile"
  role = aws_iam_role.jfrog_ec2_role.name
}

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
  source_security_group_id = aws_security_group.lb-sg.id
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

  image_id      = data.aws_ami.jfrog-ami.id
  instance_type = "t2.large"

  key_name = "jfrog_vm"

  ebs_optimized = true
  iam_instance_profile {
    name = aws_iam_instance_profile.jfrog_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = var.lt_ebs_volume
    }
  }

  vpc_security_group_ids = [aws_security_group.gp-lt-sg.id]

  instance_initiated_shutdown_behavior = "terminate"

  instance_market_options {
    market_type = "spot"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "gp-jfrog"
    }
  }
}