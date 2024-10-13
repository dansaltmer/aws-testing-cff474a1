output "docdb_username" {
  value       = aws_docdbelastic_cluster.db.admin_user_name
  description = "document db user name"
}

output "docdb_password" {
  value       = aws_docdbelastic_cluster.db.admin_user_password
  description = "document db password"
}
