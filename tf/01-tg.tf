

resource "aws_lb_target_group" "app_tg" {
  name     = "tg-${var.project}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-299"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  target_type = "instance"

  deregistration_delay  = 30
  slow_start            = 0
}
