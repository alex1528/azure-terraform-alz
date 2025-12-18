# versions.tf - Terraform and Provider Version Constraints

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # backend "azurerm" {
  #   # Backend configuration should be provided via:
  #   # 1. Backend config file (recommended): terraform init -backend-config=backend.conf
  #   # 2. CLI parameters during init
  #   # 3. Environment variables (TF_VAR_* pattern)
  #   #
  #   # Example backend.conf file:
  #   # resource_group_name   = "rg-terraform-state"
  #   # storage_account_name  = "storageaccountname"
  #   # container_name        = "tfstate"
  #   # key                   = "alz/terraform.tfstate"
  #   # use_azuread_auth      = true
  #   # subscription_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  #   # tenant_id             = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  # }
}