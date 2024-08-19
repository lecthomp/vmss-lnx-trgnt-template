# Define the log file path
$logFile = "C:\Logs\Remove-MicrosoftMonitoringAgent.log"

# Function to write to log
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp : $message"
    Add-Content -Path $logFile -Value $logEntry
}

# Function to remove Microsoft Monitoring Agent Extension from a VM
function Remove-MicrosoftMonitoringAgent {
    param (
        [string]$subscriptionId,
        [string]$resourceGroupName,
        [string]$vmName,
        [string]$osType,
        [string]$vmState
    )

    try {
        Write-Log "Processing VM: $vmName in subscription: $subscriptionId, Resource Group: $resourceGroupName"

        # Set the subscription context
        Set-AzContext -SubscriptionId $subscriptionId

        # Get the list of extensions on the VM
        $extensions = Get-AzVMExtension -ResourceGroupName $resourceGroupName -VMName $vmName -ErrorAction Stop

        # Check if Microsoft Monitoring Agent extension is installed
        $mmaExtension = $extensions | Where-Object { $_.Publisher -eq "Microsoft.EnterpriseCloud.Monitoring" -and $_.Type -eq "MicrosoftMonitoringAgent" }

        if ($null -ne $mmaExtension) {
            Write-Log "Removing Microsoft Monitoring Agent from VM: $vmName"

            # Remove the extension
            Remove-AzVMExtension -ResourceGroupName $resourceGroupName -VMName $vmName -Name $mmaExtension.Name -Force -ErrorAction Stop

            Write-Log "Successfully removed Microsoft Monitoring Agent from VM: $vmName"
        } else {
            Write-Log "Microsoft Monitoring Agent not found on VM: $vmName. Skipping..."
        }

        # Return VM to its original state if it was running or deallocated
        if ($vmState -eq "VM running") {
            Start-AzVM -ResourceGroupName $resourceGroupName -VMName $vmName -NoWait -ErrorAction Stop
            Write-Log "Started VM: $vmName"
        } elseif ($vmState -eq "VM deallocated") {
            Stop-AzVM -ResourceGroupName $resourceGroupName -VMName $vmName -NoWait -ErrorAction Stop
            Write-Log "Deallocated VM: $vmName"
        }

    } catch {
        Write-Log "Error processing VM: $vmName in subscription: $subscriptionId - $_"
    }
}

# Function to process VMs in parallel
function Process-VMsInParallel {
    param (
        [array]$vms
    )

    # Using Parallel processing for faster execution
    $vms | ForEach-Object -Parallel {
        param (
            $vm
        )

        # Ensure the Remove-MicrosoftMonitoringAgent function is defined in the current context
        using module $using:MyScriptModule

        # Call the function
        Remove-MicrosoftMonitoringAgent -subscriptionId $vm.SubscriptionId `
                                        -resourceGroupName $vm.ResourceGroupName `
                                        -vmName $vm.Name `
                                        -osType $vm.StorageProfile.OsDisk.OsType `
                                        -vmState $vm.ProvisioningState

    } -ThrottleLimit 50
}

# Main execution block
function Main {
    # Load all subscriptions
    $subscriptions = Get-AzSubscription

    foreach ($subscription in $subscriptions) {
        Set-AzContext -SubscriptionId $subscription.Id

        # Get all VMs in the current subscription
        $vms = Get-AzVM

        # Process VMs in parallel
        Process-VMsInParallel -vms $vms
    }
}

# Start the main execution
Main
