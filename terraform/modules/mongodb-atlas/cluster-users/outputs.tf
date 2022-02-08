output "db_password" {
  value       = random_password.database_password.result
  sensitive = true
}
