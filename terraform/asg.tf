resource "aws_placement_group" "jfrog-dev" {
  name     = "dev"
  strategy = "cluster"
}

resource "aws_autoscaling_group" "jfrog-asg" {
  name = "jfrog-asg-dev"
  max_size = 3
  min_size = 1
  health_check_grace_period = 300
  health_check_type = "ELB"
  desired_capacity = 1
  force_delete = true
  placement_group = aws_placement_group.jfrog-dev.id
  vpc_zone_identifier = aws_subnet.gp-jfrog-private-subnet[*].id
  service_linked_role_arn = data.aws_iam_role.serviceroleasg.arn
  target_group_arns = [ aws_lb_target_group.jfrog-alb-tg.arn ]

  launch_template {
    id = aws_launch_template.gp-lt.id
    version = "$Latest"
  }

  tag {
    key = "Name"
    value = "Jfrog-asg"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "jfrog-server-cpu-util" {
  name = "jfrog-asg-target-policy-cpu"
  autoscaling_group_name = aws_autoscaling_group.jfrog-asg.name
  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70
    disable_scale_in = true
  }
}