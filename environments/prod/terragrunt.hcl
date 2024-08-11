terraform {
  source = "../../modules/vmss"
}

inputs = {
  location            = "eastus"
  resource_group_name = "dev-rg"
  vmss_name           = "dev-vmss"
  admin_username      = "adminuser"
  admin_password      = "P@ssw0rd123!"
  managed_identity_id = "/subscriptions/your-subscription-id/resourceGroups/dev-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/managedIdentity"
  subnet_id           = "/subscriptions/your-subscription-id/resourceGroups/dev-rg/providers/Microsoft.Network/virtualNetworks/dev-vnet/subnets/default"
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

  # Autoscale settings
  autoscale_profile_name     = "dev-autoscale-profile"
  metric_name                = "Percentage CPU"
  metric_operator            = "GreaterThan"
  metric_statistic           = "Average"
  metric_threshold           = 75
  metric_time_aggregation    = "Average"
  metric_time_grain          = "PT1M"
  metric_time_window         = "PT5M"
  scale_action_direction     = "Increase"
  scale_action_type          = "ChangeCount"
  scale_action_value         = "1"
  scale_action_cooldown      = "PT1M"

  # Monitor settings JSON (if any)
  monitor_settings_json = jsonencode({
    "performanceCounters" = {
      "enabled": true,
      "counters": [
        {
          "counterSpecifier": "\\Processor(_Total)\\% Processor Time",
          "sampleRate": "PT1M",
          "unit": "Percent"
        }
      ]
    }
  })
}
