output "summary" {
  description = "VDI policy and identity control summary for one AWS site."
  value = {
    site                         = var.site_name
    broker_security_group_id     = aws_security_group.broker.id
    desktop_security_group_id    = aws_security_group.desktop.id
    broker_role_arn              = aws_iam_role.broker.arn
    broker_instance_profile_name = aws_iam_instance_profile.broker.name
    broker_policy_arn            = aws_iam_policy.broker_identity.arn
  }
}
