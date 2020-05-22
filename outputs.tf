output "elastic_ip" {
  value = aws_eip.elastic_ip.public_ip
}

output "asg_name" {
  value = aws_autoscaling_group.autoscaling_group.name
}

output "launch_template_name" {
  value = aws_launch_template.launch_template.name
}

output "iam_role_arn" {
  value = aws_iam_role.instance_role.arn
}

output "iam_role_id" {
  value = aws_iam_role.instance_role.id
}

output "security_group_id" {
  value = aws_security_group.lc_security_group.id
}
