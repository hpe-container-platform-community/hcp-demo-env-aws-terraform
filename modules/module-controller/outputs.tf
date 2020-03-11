
output "id" {
  value = aws_instance.controller.id
}

output "public_ip" {
  value = aws_eip.controller.public_ip
}

output "private_ip" {
  value = aws_instance.controller.private_ip
}

output "public_dns" {
  value = aws_eip.controller.public_dns
}

output "private_dns" {
  value = aws_instance.controller.private_dns
}