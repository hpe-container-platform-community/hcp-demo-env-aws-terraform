output "id" {
  value = aws_instance.gateway.id
}
output "private_ip" {
  value = aws_instance.gateway.private_ip
}
output "private_dns" {
  value = aws_instance.gateway.private_dns
}
output "public_ip" {
  value = var.create_eip ? aws_eip.gateway[0].public_ip : aws_instance.gateway.public_ip
}
output "public_dns" {
  value = var.create_eip ? aws_eip.gateway[0].public_dns : aws_instance.gateway.public_dns
}