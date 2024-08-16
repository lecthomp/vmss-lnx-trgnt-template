# Ensure you are logged in
Connect-AzAccount

# Set the subscription context
$subscriptionId = "<YourSubscriptionId>"
Select-AzSubscription -SubscriptionId $subscriptionId

# Define the log file path
$logFilePath = "C:\Path\To\Your\LogFile.log"

# Function to log messages
function Log-Message {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Write-Output $logMessage | Out-File -FilePath $logFilePath -Append
}

# Get all VMs
$vms = Get-AzVM

# Run the script against 5 VMs concurrently
$vms | ForEach-Object -Parallel {
    param ($vm, $logFilePath)

    function Log-Message {
        param (
            [string]$message
        )
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "$timestamp - $message"
        Write-Output $logMessage | Out-File -FilePath $logFilePath -Append
    }

    try {
        # Get the VM state
        $vmState = (Get-AzVM -ResourceGroupName $using:vm.ResourceGroupName -Name $using:vm.Name -Status).PowerState

        # Determine the OS type
        $osType = $using:vm.StorageProfile.OSDisk.OSType

        # Set the extension names based on OS type
        $extensionsToRemove = @()
        if ($osType -eq "Windows") {
            $extensionsToRemove += "MicrosoftMonitoringAgent"
        } elseif ($osType -eq "Linux") {
            $extensionsToRemove += "MicrosoftMonitoringAgent"
            $extensionsToRemove += "OmsAgentForLinux"
        }

        Log-Message "Processing VM: $($using:vm.Name) in resource group: $($using:vm.ResourceGroupName)"

        # Check if the VM is running or deallocated
        if ($vmState -eq 'VM running') {
            foreach ($extension in $extensionsToRemove) {
                # Remove extensions if they exist
                Remove-AzVmExtension -ResourceGroupName $using:vm.ResourceGroupName -VMName $using:vm.Name -Name $extension -ErrorAction SilentlyContinue
                Log-Message "Removed extension '$extension' from VM: $($using:vm.Name)"
            }
        } elseif ($vmState -eq 'VM deallocated') {
            # Start the VM
            Start-AzVM -ResourceGroupName $using:vm.ResourceGroupName -Name $using:vm.Name
            Log-Message "Started VM: $($using:vm.Name)"

            # Wait until the VM is running
            while ((Get-AzVM -ResourceGroupName $using:vm.ResourceGroupName -Name $using:vm.Name -Status).PowerState -ne 'VM running') {
                Start-Sleep -Seconds 10
            }

            foreach ($extension in $extensionsToRemove) {
                # Remove extensions if they exist
                Remove-AzVmExtension -ResourceGroupName $using:vm.ResourceGroupName -VMName $using:vm.Name -Name $extension -ErrorAction SilentlyContinue
                Log-Message "Removed extension '$extension' from VM: $($using:vm.Name)"
            }

            # Stop and deallocate the VM again
            Stop-AzVM -ResourceGroupName $using:vm.ResourceGroupName -Name $using:vm.Name -Force
            Log-Message "Deallocated VM: $($using:vm.Name)"
        }
    } catch {
        # Log the error
        Log-Message "Error processing VM: $($using:vm.Name). Error details: $_"
    }

} -ThrottleLimit 5 -ArgumentList $logFilePath

Log-Message "Completed processing all VMs."
