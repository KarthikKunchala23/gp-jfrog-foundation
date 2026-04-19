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

    image_id = data.aws_ami.jfrog-ami.id

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
      security_groups = [ aws_security_group.gp-lt-sg.id ]
    }

    placement {
      availability_zone = "ap-south-1"
    }


    tags = {
        Name = "gp-jfrog-lt"
    }

    user_data = base64encode(<<-EOF
#!/bin/bash
set -e

echo "Starting JFrog bootstrap..."

SYSTEM_YAML="/opt/jfrog/artifactory/var/etc/system.yaml"

# Fetch instance metadata
HOST_IP=$(hostname -I | awk '{print $1}')
HOSTNAME=$(hostname)

# Replace DB config with RDS PostgreSQL
cat > $SYSTEM_YAML <<EOL
configVersion: 1

shared:
  node:
    id: $HOSTNAME
    ip: $HOST_IP

  database:
    type: postgresql
    driver: org.postgresql.Driver
    url: jdbc:postgresql://${aws_db_instance.jfrog-postgres.endpoint}/artifactory
    username: ${var.db_username}
    password: ${var.db_password}

  security:
    joinKeyFile: /opt/jfrog/artifactory/var/etc/security/join.key
    masterKeyFile: /opt/jfrog/artifactory/var/etc/security/master.key

# binaryStore:
#   type: filesystem
#   filesystem:
#     dir: /mnt/efs/artifactory
EOL

# Ensure permissions
chown artifactory:artifactory $SYSTEM_YAML
chmod 600 $SYSTEM_YAML

# Restart Artifactory
systemctl restart artifactory

echo "JFrog bootstrap completed"
EOF
)
}