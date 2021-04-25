
output "id" {
  value = aws_instance.controller.id
}

output "arn" {
  value = aws_instance.controller.arn
}

output "public_ip" {
  value = var.create_eip ? aws_eip.controller[0].public_ip : aws_instance.controller.public_ip
}

output "private_ip" {
  value = aws_instance.controller.private_ip
}

output "public_dns" {
  value = var.create_eip ? aws_eip.controller[0].public_dns : aws_instance.controller.public_dns
}

output "private_dns" {
  value = aws_instance.controller.private_dns
}