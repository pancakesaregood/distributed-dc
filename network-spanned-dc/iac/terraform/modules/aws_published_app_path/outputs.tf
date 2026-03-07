output "summary" {
  description = "Published app path summary for one AWS site."
  value = {
    site                 = var.site_name
    load_balancer_arn    = aws_lb.this.arn
    load_balancer_dns    = aws_lb.this.dns_name
    load_balancer_zone   = aws_lb.this.zone_id
    listener_port        = var.listener_port
    target_group_arn     = aws_lb_target_group.app.arn
    health_check_path    = var.health_check_path
    backend_target_count = length(var.backend_ipv4_targets)
    traffic_mode         = length(var.backend_ipv4_targets) > 0 ? "forward" : "fixed-response"
    web_acl_arn          = aws_wafv2_web_acl.this.arn
    security_group_id    = aws_security_group.alb.id
  }
}
