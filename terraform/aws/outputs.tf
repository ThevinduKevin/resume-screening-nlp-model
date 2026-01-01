output "public_ip" {
  value = aws_instance.ml_vm.public_ip
}

output "instance_id" {  # ADD THIS
  value = aws_instance.ml_api.id
}