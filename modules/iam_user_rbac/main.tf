terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

resource "azuread_user" "this" {
  user_principal_name = var.user_principal_name
  display_name        = var.display_name
  password            = var.initial_password
  force_password_change = var.force_password_change
  account_enabled       = true
}

data "azuread_user" "created" {
  object_id = azuread_user.this.object_id
}

resource "azurerm_role_assignment" "assignments" {
  for_each             = { for i, ra in var.role_assignments : i => ra }
  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = data.azuread_user.created.object_id
}
