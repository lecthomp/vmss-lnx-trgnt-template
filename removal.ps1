# Define the log file path
$logFile = "C:\Temp\vm_extension_removal_log.txt"

# Function to log messages
function Log-Message {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -Append -FilePath $logFile
}

# Function to check if the MMA or OMSAgentForLinux extension is installed
function Check-ExtensionInstalled {
    param (
        [string]$resourceGroupName,
        [string]$vmName,
        [string]$osType
    )

    $extensionName = if ($osType -eq "Windows") { "MicrosoftMonitoringAgent" } else { "OMSAgentForLinux" }

    $extension = Get-AzVMExtension -ResourceGroupName $resourceGroupName -VMName $vmName -Name $extensionName -ErrorAction SilentlyContinue
    return $null -ne $extension
}

# Function to remove extensions from a VM
function Remove-Extensions {
    param (
        [string]$resourceGroupName,
        [string]$vmName,
        [string]$osType,
        [string]$vmState
    )
    
    $extensionName = if ($osType -eq "Windows") { "MicrosoftMonitoringAgent" } else { "OMSAgentForLinux" }
    
    try {
        if ($vmState -eq "deallocated") {
            # Start the VM
            Log-Message "Starting VM ${vmName} in resource group ${resourceGroupName}."
            Start-AzVM -ResourceGroupName $resourceGroupName -Name $vmName

            # Wait until the VM is running
            $vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName
            while ($vm.ProvisioningState -ne 'Succeeded' -or $vm.PowerState -ne 'VM running') {
                Start-Sleep -Seconds 10
                $vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName
            }

            # Remove the extension
            Log-Message "Removing extension ${extensionName} from VM ${vmName}."
            Remove-AzVMExtension -ResourceGroupName $resourceGroupName -VMName $vmName -Name $extensionName -Force

            # Stop the VM
            Log-Message "Stopping VM ${vmName}."
            Stop-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -Force
        } elseif ($vmState -eq "VM running") {
            # Remove the extension
            Log-Message "Removing extension ${extensionName} from running VM ${vmName}."
            Remove-AzVMExtension -ResourceGroupName $resourceGroupName -VMName $vmName -Name $extensionName -Force
        }
    } catch {
        Log-Message "Error removing extension from VM ${vmName}: $($_.Exception.Message)"
    }
}

# Main script
$vmList = Get-AzVM

$vmList | ForEach-Object -Parallel {
    param (
        $vm,
        $logFile
    )

    # Import the required modules in the parallel runspace
    Import-Module Az.Compute
    Import-Module Az.Resources

    # Define the log file path inside the parallel block
    $logFile = "C:\Temp\vm_extension_removal_log.txt"

    # Function to log messages in the parallel block
    function Log-Message {
        param (
            [string]$message
        )
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp - $message" | Out-File -Append -FilePath $logFile
    }

    # Function to check if the MMA or OMSAgentForLinux extension is installed
    function Check-ExtensionInstalled {
        param (
            [string]$resourceGroupName,
            [string]$vmName,
            [string]$osType
        )

        $extensionName = if ($osType -eq "Windows") { "MicrosoftMonitoringAgent" } else { "OMSAgentForLinux" }

        $extension = Get-AzVMExtension -ResourceGroupName $resourceGroupName -VMName $vmName -Name $extensionName -ErrorAction SilentlyContinue
        return $null -ne $extension
    }

    # Parameters for the VM
    $resourceGroupName = $vm.ResourceGroupName
    $vmName = $vm.Name
    $osType = $vm.StorageProfile.OSDisk.OSType
    $vmState = $vm.PowerState -replace "PowerState/", ""

    Log-Message "Processing VM ${vmName} in resource group ${resourceGroupName}."

    # Check if the extension is installed
    if (Check-ExtensionInstalled -resourceGroupName $resourceGroupName -vmName $vmName -osType $osType) {
        # Call the function to remove extensions if installed
        Remove-Extensions -resourceGroupName $resourceGroupName -vmName $vmName -osType $osType -vmState $vmState
    } else {
        Log-Message "Skipping VM ${vmName} as it does not have the ${extensionName} extension installed."
    }
} -ThrottleLimit 5 -ArgumentList $_, $logFile

Log-Message "VM extension removal process completed."
