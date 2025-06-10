


output "target_group" {
  value = {
    name  = aws_lb_target_group.app_tg.name
    arn   = aws_lb_target_group.app_tg.arn
  }
}

output "aws_lb" {
  value = aws_lb.app_alb.dns_name
}

output "region" {
  value = local.region
}


output "asg" {
  value = {
    desired = aws_autoscaling_group.asg.desired_capacity
    id = aws_autoscaling_group.asg.id
  }
}

output "ansible_ssm_bucket" {
  value = aws_s3_bucket.ansible_ssm.id
}

output "ruby_scaffold" {
  value = aws_s3_bucket.ruby.id
}
