output "public_ip" {
  value = aws_instance.ml_vm.public_ip
}

# output "bucket_name" {
#   value = aws_s3_bucket.ml_bucket.bucket
# }