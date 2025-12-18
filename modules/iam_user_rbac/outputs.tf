output "user_object_id" {
  description = "Object ID of the created Azure AD user"
  value       = azuread_user.this.object_id
}

output "user_principal_name" {
  description = "UPN of the created Azure AD user"
  value       = azuread_user.this.user_principal_name
}
