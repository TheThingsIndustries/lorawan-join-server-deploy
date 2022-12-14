output "server_role_arn" {
  description = "Server IAM role ARN"
  value       = aws_iam_role.server.arn
}

output "provisioner_passwords" {
  description = "Provisioner passwords"
  sensitive   = true
  value = [
    for key, value in var.provisioners : {
      username = key
      name     = value.name
      password = random_password.provisioner_password[key].result
    }
  ]
}
