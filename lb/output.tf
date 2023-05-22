# --- lb/outout.tf

output "lb_target_group_arn" {
  value = aws_lb_target_group.ps_tg.arn
}
