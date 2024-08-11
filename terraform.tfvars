# terraform.tfvars

# Azure region where the resources will be deployed
location = "eastus"

# Name of the resource group
resource_group_name = "dev-rg"

# Name of the VM scale set
vmss_name = "dev-vmss"

# Admin username for the VM instances
admin_username = "adminuser"

# Admin password for the VM instances (ensure this is secure)
admin_password = "P@ssw0rd123!"

# The ID of the user-assigned managed identity
managed_identity_id = "/subscriptions/238d0fdb-eb9d-4d9d-a000-ba683d991ec9/resourceGroups/archlab-01-p1-ama-policy-umi-rg-001/providers/Microsoft.ManagedIdentity/userAssignedIdentities/archlab-01-p1-ama-policy-umi-001"

# The ID of the subnet where the VM instances will be deployed
subnet_id = "/subscriptions/your-subscription-id/resourceGroups/dev-rg/providers/Microsoft.Network/virtualNetworks/dev-vnet/subnets/default"

# The minimum number of VM instances to maintain in the scale set
instance_count_min = 1

# The maximum number of VM instances to maintain in the scale set
instance_count_max = 3

# Caching setting for the OS disk
os_disk_caching = "ReadWrite"

# Storage account type for the OS disk
os_disk_storage_account_type = "Premium_LRS"

# Offer for the image (Ubuntu Server in this case)
image_offer = "UbuntuServer"

# Publisher of the image
image_publisher = "Canonical"

# SKU for the image
image_sku = "18.04-LTS"

# Version of the image
image_version = "latest"

# SKU for the VM scale set (e.g., Standard_DS1_v2)
vmss_sku = "Standard_DS1_v2"

# Tags to be applied to all resources
tags = {
  environment = "dev"
  project     = "vmss-terragrunt"
}

# Autoscale settings
autoscale_profile_name  = "dev-autoscale-profile"
metric_name             = "Percentage CPU"
metric_operator         = "GreaterThan"
metric_statistic        = "Average"
metric_threshold        = 75
metric_time_aggregation = "Average"
metric_time_grain       = "PT1M"
metric_time_window      = "PT5M"
scale_action_direction  = "Increase"
scale_action_type       = "ChangeCount"
scale_action_value      = "1"
scale_action_cooldown   = "PT1M"

# JSON settings for Azure Monitor Agent (if applicable)
monitor_settings_json = <<EOF
{
  "performanceCounters": {
    "enabled": true,
    "counters": [
      {
        "counterSpecifier": "\\Processor(_Total)\\% Processor Time",
        "sampleRate": "PT1M",
        "unit": "Percent"
      }
    ]
  }
}
EOF

