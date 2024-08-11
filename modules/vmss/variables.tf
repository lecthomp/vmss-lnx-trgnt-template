variable "location" {
  description = "The Azure region to deploy resources into."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
}

variable "vmss_name" {
  description = "The name of the VM scale set."
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM instances."
  type        = string
}

variable "admin_password" {
  description = "Admin password for the VM instances."
  type        = string
}

variable "managed_identity_id" {
  description = "The ID of the user-assigned managed identity."
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet for the VM instances."
  type        = string
}

variable "instance_count_min" {
  description = "The minimum number of VM instances."
  type        = number
  default     = 1
}

variable "instance_count_max" {
  description = "The maximum number of VM instances."
  type        = number
  default     = 5
}

variable "os_disk_caching" {
  description = "Caching setting for the OS disk."
  type        = string
  default     = "ReadWrite"
}

variable "os_disk_storage_account_type" {
  description = "Storage account type for the OS disk."
  type        = string
  default     = "Premium_LRS"
}

variable "image_offer" {
  description = "Offer for the image."
  type        = string
  default     = "UbuntuServer"
}

variable "image_publisher" {
  description = "Publisher of the image."
  type        = string
  default     = "Canonical"
}

variable "image_sku" {
  description = "SKU for the image."
  type        = string
  default     = "18.04-LTS"
}

variable "image_version" {
  description = "Version of the image."
  type        = string
  default     = "latest"
}

variable "vmss_sku" {
  description = "SKU for the VM scale set."
  type        = string
  default     = "Standard_DS1_v2"
}

variable "tags" {
  description = "Tags to be applied to the resources."
  type        = map(string)
  default     = {}
}

# Autoscale Metric and Action Variables
variable "autoscale_profile_name" {
  description = "The name of the autoscale profile."
  type        = string
  default     = "defaultProfile"
}

variable "metric_name" {
  description = "The name of the metric to trigger scaling."
  type        = string
  default     = "Percentage CPU"
}

variable "metric_operator" {
  description = "The operator to use for the metric comparison."
  type        = string
  default     = "GreaterThan"
}

variable "metric_statistic" {
  description = "The statistic type to use for the metric."
  type        = string
  default     = "Average"
}

variable "metric_threshold" {
  description = "The threshold value for the metric."
  type        = number
  default     = 75
}

variable "metric_time_aggregation" {
  description = "The time aggregation method for the metric."
  type        = string
  default     = "Average"
}

variable "metric_time_grain" {
  description = "The granularity of the metric data."
  type        = string
  default     = "PT1M"
}

variable "metric_time_window" {
  description = "The time window for the metric evaluation."
  type        = string
  default     = "PT5M"
}

variable "scale_action_direction" {
  description = "The direction to scale (Increase/Decrease)."
  type        = string
  default     = "Increase"
}

variable "scale_action_type" {
  description = "The type of scaling action (ChangeCount, ExactCount, PercentChangeCount)."
  type        = string
  default     = "ChangeCount"
}

variable "scale_action_value" {
  description = "The value to scale by."
  type        = string
  default     = "1"
}

variable "scale_action_cooldown" {
  description = "The cooldown period before another scaling action can occur."
  type        = string
  default     = "PT1M"
}

variable "monitor_settings_json" {
  description = "The JSON settings for the Azure Monitor Agent."
  type        = string
  default     = "{}"  # Use an empty JSON string as the default
}

