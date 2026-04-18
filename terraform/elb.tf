resource "aws_security_group" "lb-sg" {
  name        = "jfrog-lb-sg"
  description = "Security group for jfrog ALB"
  vpc_id      = aws_vpc.gp-jfrog-vpc.id

  tags = {
    Name = "jfrog-lb-sg"
  }
}

resource "aws_security_group_rule" "jfrog_lb_ingress_private" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "HTTP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb-sg.id
}

# Allow egress everywhere (for RDS to reach S3, KMS, etc.)
resource "aws_security_group_rule" "jfrog_lb_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb-sg.id
}

resource "aws_lb" "jfrog-alb" {
  name               = "jfrog-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb-sg.id]
  subnets            = [for subnet in aws_subnet.gp-jfrog-public-subnet : subnet.id]

  enable_deletion_protection = false

  tags = {
    Environment = "Development"
  }
}

resource "aws_lb_target_group" "jfrog-alb-tg" {
  name        = "jfrog-lb-alb-tg"
  target_type = "instance"
  port        = 8082
  protocol    = "HTTP"
  vpc_id      = aws_vpc.gp-jfrog-vpc.id

  health_check {
    path = "/"
    port = "8082"
    protocol = "HTTP"
    matcher = "200-399"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "jfrog-front_end" {
  load_balancer_arn = aws_lb.jfrog-alb.arn
  port              = "8082"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jfrog-alb-tg.arn
  }
}