output "docdb_username" {
  value       = module.private_document_db.docdb_username
  description = "docdb username"
}

output "docdb_password" {
  value       = module.private_document_db.docdb_password
  description = "docdb password"
  sensitive   = true
}
