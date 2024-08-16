# Ensure you are logged in
Connect-AzAccount

# Set the subscription context
$subscriptionId = "<YourSubscriptionId>"
Select-AzSubscription -SubscriptionId $subscriptionId

# Get all VMs
$vms = Get-AzVM

foreach ($vm in $vms) {
    try {
        # Get the VM state
        $vmState = (Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status).PowerState

        # Determine the OS type
        $osType = $vm.StorageProfile.OSDisk.OSType

        # Set the extension names based on OS type
        $extensionsToRemove = @()
        if ($osType -eq "Windows") {
            $extensionsToRemove += "MicrosoftMonitoringAgent"
        } elseif ($osType -eq "Linux") {
            $extensionsToRemove += "MicrosoftMonitoringAgent"
            $extensionsToRemove += "OmsAgentForLinux"
        }

        # Check if the VM is running or deallocated
        if ($vmState -eq 'VM running') {
            foreach ($extension in $extensionsToRemove) {
                # Remove extensions if they exist
                Remove-AzVmExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -Name $extension -ErrorAction SilentlyContinue
            }
        } elseif ($vmState -eq 'VM deallocated') {
            # Start the VM
            Start-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name

            # Wait until the VM is running
            while ((Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status).PowerState -ne 'VM running') {
                Start-Sleep -Seconds 10
            }

            foreach ($extension in $extensionsToRemove) {
                # Remove extensions if they exist
                Remove-AzVmExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -Name $extension -ErrorAction SilentlyContinue
            }

            # Stop and deallocate the VM again
            Stop-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force
        }
    } catch {
        Write-Error "An error occurred with VM $($vm.Name): $_"
    }
}

Write-Output "Completed processing all VMs."
