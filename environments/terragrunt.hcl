# Configure the remote backend for Terraform state
remote_state {
  backend = "azurerm"
  config = {
    resource_group_name   = "terraform-state-rg"
    storage_account_name  = "terraformstate"
    container_name        = "tfstate"
    key                   = "${path_relative_to_include()}/terraform.tfstate"
  }
}

# Generate a provider.tf file in each environment that includes the provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "azurerm" {
  features {}
}
EOF
}

# Include block to inherit configurations from this file
include {
  path = find_in_parent_folders()
}

# Common inputs for all environments (if any)
inputs = {
  tags = {
    project = "vmss-terragrunt"
  }
}
