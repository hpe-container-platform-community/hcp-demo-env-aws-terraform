output "security_group_main_id" {
  value = aws_default_security_group.main.id
}
output "subnet_main_id" {
  value = aws_subnet.main.id
}