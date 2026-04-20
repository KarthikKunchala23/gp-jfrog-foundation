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

  user_data = base64encode(<<-EOF
#!/bin/bash
set -e
set -x
exec > /var/log/userdata.log 2>&1

echo "Starting JFrog bootstrap..."

SYSTEM_YAML="/opt/jfrog/artifactory/var/etc/system.yaml"
SEC_DIR="/opt/jfrog/artifactory/var/etc/security"

# Fix apt lock issue
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  echo "Waiting for apt lock..."
  sleep 5
done

#Install AWSCLI
sudo apt update -y
sudo apt install -y unzip curl

cd /tmp
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip -q awscliv2.zip
sudo ./aws/install

export PATH=$PATH:/usr/local/bin

# Start service
sudo systemctl start artifactory

echo "Waiting for router (port 8046)..."

until curl -s http://localhost:8046/router/api/v1/system/ping > /dev/null; do
  sleep 10
done

echo "Router is up. Fetching keys..."

sudo mkdir -p $SEC_DIR

sudo aws s3 cp s3://jfrog-keys-bucket/jfrog/join.key $SEC_DIR/join.key
sudo aws s3 cp s3://jfrog-keys-bucket/jfrog/master.key $SEC_DIR/master.key

sudo chown artifactory:artifactory $SEC_DIR/*
sudo chmod 600 $SEC_DIR/*

echo "Updating system.yaml with DB config..."

sudo cat > $SYSTEM_YAML <<EOL
shared:
  database:
    type: postgresql
    driver: org.postgresql.Driver
    url: jdbc:postgresql://${aws_db_instance.jfrog-postgres.endpoint}/artifactory
    username: ${var.db_username}
    password: ${var.db_password}
EOL

echo "Restarting Artifactory..."

sudo systemctl restart artifactory

echo "JFrog bootstrap completed"
EOF
)

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "gp-jfrog"
    }
  }
}