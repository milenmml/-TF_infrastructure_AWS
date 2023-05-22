# --- lb/main.tf

resource "aws_lb" "ps_lb" {
  name               = "ps-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.public_sg]
  subnets            = var.public_subnets
  enable_cross_zone_load_balancing = true
}
resource "aws_lb_target_group" "ps_tg" {
  name     = "ps-tg-lb-${substr(uuid(), 0, 3)}"
  port     = var.tg_port #80
  protocol = var.tg_protocol #HTTP
  vpc_id   = var.vpc_id  
  health_check {
    healthy_threshold = var.lb_healty_treshold #2
    unhealthy_threshold = var.lb_unhealthy_threshold #2
    timeout = var.lb_timeout #3
    interval = var.lb_interval #30
  }
}
resource "aws_lb_listener" "ps_lb_listener" {
  load_balancer_arn = aws_lb.ps_lb.arn
  port              = var.listener_port
  protocol          = var.listener_protocol
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ps_tg.arn
    
}
}
