# modules/core_policies/main.tf - ALZ Core Security Policies

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }
}

# ============================================================================
# CORE SECURITY POLICY DEFINITIONS
# ============================================================================

# These are essential security policies focusing on the most critical controls
# without the overwhelming complexity of the full ALZ/CIS policy suite

locals {
  # Core security policies that every Azure environment should have
  core_policies = {
    # Storage Security
    require_storage_https = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"
      display_name         = "Secure transfer to storage accounts should be enabled"
      description          = "Audit requirement of Secure transfer in your storage account"
    }

    # SQL Security  
    require_sql_tde = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/17k78e20-9358-41c9-923c-fb736d382a12"
      display_name         = "Transparent Data Encryption on SQL databases should be enabled"
      description          = "Transparent data encryption should be enabled to protect data-at-rest"
    }

    # VM Backup
    require_vm_backup = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/013e242c-8828-4970-87b3-ab247555486d"
      display_name         = "Azure Backup should be enabled for Virtual Machines"
      description          = "Ensure protection of your Azure Virtual Machines by enabling Azure Backup"
    }

    # Resource Location Compliance
    allowed_locations = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
      display_name         = "Allowed locations"
      description          = "This policy enables you to restrict the locations your organization can specify when deploying resources"
      parameters = {
        listOfAllowedLocations = {
          value = var.allowed_locations
        }
      }
    }

    # Resource Tagging
    require_environment_tag = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
      display_name         = "Require a tag on resource groups"
      description          = "Enforces presence of a required tag on resource groups"
      parameters = {
        tagName = {
          value = "Environment"
        }
      }
    }

    require_cost_center_tag = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
      display_name         = "Require a tag on resource groups"
      description          = "Enforces presence of CostCenter tag on resource groups"
      parameters = {
        tagName = {
          value = "CostCenter"
        }
      }
    }

    require_owner_tag = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
      display_name         = "Require a tag on resource groups"
      description          = "Enforces presence of Owner tag on resource groups"
      parameters = {
        tagName = {
          value = "Owner"
        }
      }
    }

    # Tag Value Enforcement (Custom Policy Definition below)
    enforce_environment_tag_value = {
      policy_definition_id = azurerm_policy_definition.rg_require_tag_value.id
      display_name         = "Require specific Environment tag value on resource groups"
      description          = "Enforces that resource groups have Environment tag with the specified value"
      parameters = {
        tagName = {
          value = "Environment"
        }
        tagValue = {
          value = var.required_environment_tag
        }
        effect = {
          value = var.policy_enforcement_mode == "Default" ? "Deny" : "Audit"
        }
      }
    }

    enforce_cost_center_tag_value = {
      policy_definition_id = azurerm_policy_definition.rg_require_tag_value.id
      display_name         = "Require specific CostCenter tag value on resource groups"
      description          = "Enforces that resource groups have CostCenter tag with the specified value"
      parameters = {
        tagName = {
          value = "CostCenter"
        }
        tagValue = {
          value = var.required_cost_center_tag
        }
        effect = {
          value = var.policy_enforcement_mode == "Default" ? "Deny" : "Audit"
        }
      }
    }

    enforce_owner_tag_value = {
      policy_definition_id = azurerm_policy_definition.rg_require_tag_value.id
      display_name         = "Require specific Owner tag value on resource groups"
      description          = "Enforces that resource groups have Owner tag with the specified value"
      parameters = {
        tagName = {
          value = "Owner"
        }
        tagValue = {
          value = var.required_owner_tag
        }
        effect = {
          value = var.policy_enforcement_mode == "Default" ? "Deny" : "Audit"
        }
      }
    }

    # Network Security
    deny_rdp_from_internet = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e372f825-a257-4fb8-9175-797a8a8627d6"
      display_name         = "RDP access from the Internet should be blocked"
      description          = "This policy denies any network security rule that allows RDP access from Internet"
    }

    deny_ssh_from_internet = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/2c89a2e5-7285-40fe-afe0-ae8654b92fab"
      display_name         = "SSH access from the Internet should be blocked"
      description          = "This policy denies any network security rule that allows SSH access from Internet"
    }

    # Key Vault Security
    require_key_vault_purge_protection = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/0b60c0b2-2dc2-4e1c-b5c9-abbed971de53"
      display_name         = "Key vaults should have purge protection enabled"
      description          = "Malicious deletion of a key vault can lead to permanent data loss"
    }

    # Monitoring and Logging
    require_activity_log_retention = {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/b02aacc0-b073-424e-8298-42b22829ee0a"
      display_name         = "Activity log should be retained for at least one year"
      description          = "This policy audits if Activity log is not set to be retained for a year or forever"
    }
  }

  # Short names for policy assignment (Azure limit: <= 24 chars)
  platform_policy_names = {
    require_storage_https               = "core-sto-https"
    require_sql_tde                     = "core-sql-tde"
    require_vm_backup                   = "core-vm-bkup"
    allowed_locations                   = "core-allowedloc"
    require_environment_tag             = "core-tag-env"
    require_cost_center_tag             = "core-tag-cost"
    require_owner_tag                   = "core-tag-owner"
    enforce_environment_tag_value       = "core-tagv-env"
    enforce_cost_center_tag_value       = "core-tagv-cost"
    enforce_owner_tag_value             = "core-tagv-owner"
    deny_rdp_from_internet              = "core-deny-rdp"
    deny_ssh_from_internet              = "core-deny-ssh"
    require_key_vault_purge_protection  = "core-kv-purge"
    require_activity_log_retention      = "core-activitylog"
  }

  lz_policy_names = {
    require_storage_https   = "lz-sto-https"
    require_sql_tde         = "lz-sql-tde"
    require_vm_backup       = "lz-vm-bkup"
    deny_rdp_from_internet  = "lz-deny-rdp"
    deny_ssh_from_internet  = "lz-deny-ssh"
    require_environment_tag = "lz-tag-env"
    require_cost_center_tag = "lz-tag-cost"
    require_owner_tag       = "lz-tag-owner"
    enforce_environment_tag_value = "lz-tagv-env"
    enforce_cost_center_tag_value = "lz-tagv-cost"
    enforce_owner_tag_value       = "lz-tagv-owner"
  }

  # Selected policy keys to assign (exclude problematic/unsupported ones)
  platform_policy_keys = [
    "require_storage_https",
    "require_sql_tde",
    "require_vm_backup",
    "allowed_locations",
    "require_environment_tag",
    "require_cost_center_tag",
    "require_owner_tag",
    "enforce_environment_tag_value",
    "enforce_cost_center_tag_value",
    "enforce_owner_tag_value",
    "require_key_vault_purge_protection",
    "require_activity_log_retention",
  ]

  landing_zones_policy_keys = [
    "require_storage_https",
    "require_sql_tde",
    "require_vm_backup",
    "deny_rdp_from_internet",
    "deny_ssh_from_internet",
    "require_environment_tag",
    "require_cost_center_tag",
    "require_owner_tag",
    "enforce_environment_tag_value",
    "enforce_cost_center_tag_value",
    "enforce_owner_tag_value",
  ]
}

# ============================================================================
# CUSTOM POLICY DEFINITION: REQUIRE TAG VALUE ON RESOURCE GROUPS
# ============================================================================

resource "azurerm_policy_definition" "rg_require_tag_value" {
  name         = "rg-require-tag-value"
  display_name = "Require a specific tag value on resource groups"
  policy_type  = "Custom"
  mode         = "All"
  description  = "Deny resource group creation/update when the specified tag is missing or its value differs from the required value."

  metadata = jsonencode({
    category = "Tags"
    version  = "1.0.0"
  })

  parameters = jsonencode({
    tagName = {
      type        = "String"
      metadata    = { displayName = "Tag Name" }
      default     = "Environment"
    }
    tagValue = {
      type        = "String"
      metadata    = { displayName = "Required Tag Value" }
      default     = "ALZ"
    }
    effect = {
      type     = "String"
      metadata = { displayName = "Effect" }
      allowedValues = ["Audit", "Deny", "Disabled"]
      default  = "Deny"
    }
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Resources/subscriptions/resourceGroups"
        },
        {
          anyOf = [
            {
              field    = "[concat('tags[', parameters('tagName'), ']')]"
              notEquals = "[parameters('tagValue')]"
            },
            {
              field  = "[concat('tags[', parameters('tagName'), ']')]"
              exists = "false"
            }
          ]
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
}

# ============================================================================
# POLICY ASSIGNMENTS - PLATFORM LEVEL
# ============================================================================

# Assign core security policies to Platform management group
resource "azurerm_management_group_policy_assignment" "platform_core_policies" {
  for_each             = var.deploy_core_policies ? toset(local.platform_policy_keys) : toset([])
  name                 = local.platform_policy_names[each.key]
  display_name         = local.core_policies[each.key].display_name
  description          = local.core_policies[each.key].description
  policy_definition_id = local.core_policies[each.key].policy_definition_id
  management_group_id  = var.platform_management_group_id
  enforce              = var.policy_enforcement_mode == "Default" ? true : false

  # Add parameters if they exist for this policy
  parameters = jsonencode(lookup(local.core_policies[each.key], "parameters", {}))
}

# ============================================================================
# POLICY ASSIGNMENTS - LANDING ZONES LEVEL
# ============================================================================

# Assign workload-specific policies to Landing Zones management group
resource "azurerm_management_group_policy_assignment" "landing_zones_core_policies" {
  for_each = var.deploy_core_policies ? toset(local.landing_zones_policy_keys) : toset([])

  name                 = local.lz_policy_names[each.key]
  display_name         = local.core_policies[each.key].display_name
  description          = local.core_policies[each.key].description
  policy_definition_id = local.core_policies[each.key].policy_definition_id
  management_group_id  = var.landing_zones_management_group_id
  enforce              = var.policy_enforcement_mode == "Default" ? true : false

  # Add parameters if they exist for this policy
  parameters = jsonencode(lookup(local.core_policies[each.key], "parameters", {}))
}

# ============================================================================
# POLICY INITIATIVE (POLICY SET) - OPTIONAL
# ============================================================================

# Create a custom policy initiative that groups our core security policies
resource "azurerm_policy_set_definition" "core_security" {
  count        = var.deploy_core_policies && var.create_policy_initiative ? 1 : 0
  name         = "alz-core-security-initiative"
  policy_type  = "Custom"
  display_name = "ALZ Core Security Initiative"
  description  = "Core security policies for Azure Landing Zones - essential controls without overwhelming complexity"

  metadata = jsonencode({
    category = "Security Center"
    version  = "1.0.0"
  })

  # Include all core policies in the initiative
  dynamic "policy_definition_reference" {
    for_each = local.core_policies
    content {
      policy_definition_id = policy_definition_reference.value.policy_definition_id
      reference_id         = policy_definition_reference.key
      parameter_values     = jsonencode(lookup(policy_definition_reference.value, "parameters", {}))
    }
  }
}

# Assign the policy initiative to the root management group
resource "azurerm_management_group_policy_assignment" "core_security_initiative" {
  count                = var.deploy_core_policies && var.create_policy_initiative ? 1 : 0
  name                 = "alz-core-security"
  display_name         = "ALZ Core Security Initiative Assignment"
  description          = "Assignment of core security policies across the Azure Landing Zone"
  policy_definition_id = azurerm_policy_set_definition.core_security[0].id
  management_group_id  = var.root_management_group_id
  enforce              = var.policy_enforcement_mode == "Default" ? true : false
}

# ============================================================================
# POLICY EXEMPTIONS (OPTIONAL)
# ============================================================================

# Create exemptions for sandbox environments where policies might be too restrictive
resource "azurerm_management_group_policy_exemption" "sandbox_exemptions" {
  for_each = var.create_sandbox_exemptions ? {
    rdp_exemption = "deny_rdp_from_internet"
  } : {}

  name                 = "sandbox-${each.value}-exemption"
  display_name         = "Sandbox Exemption for ${each.value}"
  description          = "Allow network access for sandbox/development environments"
  management_group_id  = var.sandbox_management_group_id
  policy_assignment_id = azurerm_management_group_policy_assignment.landing_zones_core_policies[each.value].id
  exemption_category   = "Waiver"
  expires_on           = var.sandbox_exemption_expiry
}

# ============================================================================
# MANAGEMENT GROUP RBAC ASSIGNMENTS (OPTIONAL)
# ============================================================================

locals {
  platform_mg_scope      = "/providers/Microsoft.Management/managementGroups/${var.platform_management_group_id}"
  landing_zones_mg_scope = "/providers/Microsoft.Management/managementGroups/${var.landing_zones_management_group_id}"
}

# Platform MG RBAC assignments
resource "azurerm_role_assignment" "platform_mg" {
  for_each             = { for a in var.platform_rbac_assignments : "${a.role_definition_name}-${a.principal_id}" => a }
  scope                = local.platform_mg_scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}

# Landing Zones MG RBAC assignments
resource "azurerm_role_assignment" "landing_zones_mg" {
  for_each             = { for a in var.landing_zones_rbac_assignments : "${a.role_definition_name}-${a.principal_id}" => a }
  scope                = local.landing_zones_mg_scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}

# ============================================================================
# DIAGNOSTIC (DINE) POLICY ASSIGNMENTS (ROOT MG SCOPE)
# ============================================================================

locals {
  root_mg_scope = "/providers/Microsoft.Management/managementGroups/${var.root_management_group_id}"
}

# Configure Azure Activity logs to stream to specified Log Analytics workspace
resource "azurerm_management_group_policy_assignment" "dine_activity_logs" {
  count                = var.deploy_diagnostic_policies && length(var.log_analytics_workspace_id) > 0 ? 1 : 0
  name                 = "dine-activity-la"
  display_name         = "Configure Activity Logs to Log Analytics"
  description          = "Deploy diagnostic settings for Azure Activity logs to stream to Log Analytics"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/2465583e-4e78-4c15-b6be-a36cbc7c8b0f"
  management_group_id  = var.root_management_group_id
  enforce              = var.policy_enforcement_mode == "Default" ? true : false
  location             = var.policy_assignment_location

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    logAnalytics = { value = var.log_analytics_workspace_id }
    logsEnabled  = { value = var.activity_logs_enabled }
  })
}

# Enable logging by category group for Bastions to Log Analytics
resource "azurerm_management_group_policy_assignment" "dine_bastion" {
  count                = var.deploy_diagnostic_policies && length(var.log_analytics_workspace_id) > 0 ? 1 : 0
  name                 = "dine-bastion-la"
  display_name         = "Enable Bastion diagnostics to Log Analytics"
  description          = "Deploy diagnostic settings for Bastion resources to stream to Log Analytics"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/f8352124-56fa-4f94-9441-425109cdc14b"
  management_group_id  = var.root_management_group_id
  enforce              = var.policy_enforcement_mode == "Default" ? true : false
  location             = var.policy_assignment_location

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    logAnalytics          = { value = var.log_analytics_workspace_id }
    categoryGroup         = { value = var.dine_category_group }
    diagnosticSettingName = { value = "setByPolicy-LogAnalytics" }
    resourceLocationList  = { value = ["*"] }
  })
}

# Configure diagnostic settings for Azure Network Security Groups to Log Analytics workspace
resource "azurerm_management_group_policy_assignment" "dine_nsg" {
  count                = var.deploy_diagnostic_policies && length(var.log_analytics_workspace_id) > 0 ? 1 : 0
  name                 = "dine-nsg-la"
  display_name         = "Enable NSG diagnostics to Log Analytics"
  description          = "Deploy diagnostic settings for NSG resources to stream to Log Analytics"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/98a2e215-5382-489e-bd29-32e7190a39ba"
  management_group_id  = var.root_management_group_id
  enforce              = var.policy_enforcement_mode == "Default" ? true : false
  location             = var.policy_assignment_location

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    logAnalytics                         = { value = var.log_analytics_workspace_id }
    diagnosticsSettingNameToUse          = { value = "setByPolicy" }
    NetworkSecurityGroupEventEnabled     = { value = var.nsg_event_enabled }
    NetworkSecurityGroupRuleCounterEnabled = { value = var.nsg_rule_counter_enabled }
  })
}
