resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_linux_virtual_machine_scale_set" "main" {
  name                = var.vmss_name
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = var.vmss_sku
  instances           = var.instance_count_max
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  disable_password_authentication = false

  computer_name_prefix = substr(var.vmss_name, 0, 9)

  identity {
    type         = "UserAssigned"
    identity_ids = [var.managed_identity_id]
  }

  network_interface {
    name    = "${var.vmss_name}-nic"
    primary = true

    ip_configuration {
      name       = "${var.vmss_name}-ipConfig"
      subnet_id  = var.subnet_id
    }
  }

  os_disk {
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
  }

  source_image_reference {
    offer     = var.image_offer
    publisher = var.image_publisher
    sku       = var.image_sku
    version   = var.image_version
  }

  tags = var.tags
}

resource "azurerm_virtual_machine_scale_set_extension" "monitor_extension" {
  name                         = "AzureMonitorLinuxAgent"
  publisher                    = "Microsoft.Azure.Monitor"
  type                         = "AzureMonitorLinuxAgent"
  type_handler_version         = "1.0"  # Or "latest"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.main.id
  auto_upgrade_minor_version   = true

  settings = var.monitor_settings_json

  # Only include `protected_settings` if you need to pass sensitive data in JSON format
  # For now, we can remove it since there's no protected setting required.
  # protected_settings = jsonencode({})  # Corrected to use jsonencode if needed
}

resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                = "${var.vmss_name}-autoscale"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.main.id

  profile {
    name = var.autoscale_profile_name
    capacity {
      default = var.instance_count_min
      minimum = var.instance_count_min
      maximum = var.instance_count_max
    }

    rule {
      metric_trigger {
        metric_name        = var.metric_name
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.main.id
        operator           = var.metric_operator
        statistic          = var.metric_statistic
        threshold          = var.metric_threshold
        time_aggregation   = var.metric_time_aggregation
        time_grain         = var.metric_time_grain
        time_window        = var.metric_time_window
      }

      scale_action {
        direction = var.scale_action_direction
        type      = var.scale_action_type
        value     = var.scale_action_value
        cooldown  = var.scale_action_cooldown
      }
    }
  }
}
