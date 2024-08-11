terraform {
  source = "../../modules/vmss"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "azurerm" {
  features {}
}
EOF
}

inputs = {
  location            = "eastus"
  resource_group_name = "archlab-dev-rg"
  vmss_name           = "archlab-dev-vmss"
  admin_username      = "adminuser"
  admin_password      = "P@ssw0rd123!"
  managed_identity_id = "/subscriptions/238d0fdb-eb9d-4d9d-a000-ba683d991ec9/resourceGroups/archlab-01-p1-ama-policy-umi-rg-001/providers/Microsoft.ManagedIdentity/userAssignedIdentities/archlab-01-p1-ama-policy-umi-001"
  subnet_id           = "/subscriptions/238d0fdb-eb9d-4d9d-a000-ba683d991ec9/resourceGroups/archlab-vnet-p0-rg-001/providers/Microsoft.Network/virtualNetworks/archlab-vnet-p0-001/subnets/archlab-web"
  instance_count_min  = 1
  instance_count_max  = 3
  os_disk_caching     = "ReadWrite"
  os_disk_storage_account_type = "Premium_LRS"
  image_offer                = "UbuntuServer"
  image_publisher            = "Canonical"
  image_sku                  = "18.04-LTS"
  image_version              = "latest"
  vmss_sku                   = "Standard_DS1_v2"
  tags = {
    environment = "dev"
    project     = "vmss-terragrunt"
  }
}
