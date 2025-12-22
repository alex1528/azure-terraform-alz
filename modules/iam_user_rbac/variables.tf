variable "user_principal_name" {
  description = "User principal name (e.g., user@contoso.com)"
  type        = string
}

variable "display_name" {
  description = "Display name for the user"
  type        = string
}

variable "initial_password" {
  description = "Initial password for the user"
  type        = string
  sensitive   = true
}

variable "force_password_change" {
  description = "Force password change at next sign-in"
  type        = bool
  default     = true
}

variable "role_assignments" {
  description = "List of role assignments with scope and role definition name"
  type = list(object({
    scope                = string
    role_definition_name = string
  }))
  default = []
}
