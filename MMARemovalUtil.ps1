param (
    [Parameter(Mandatory = $true)]
    [string]$TopLevelMgmtGrp,  # The top-level management group as a parameter

    [Parameter(Mandatory = $true)]
    [string]$LogFilePath  # Log file path as a parameter
)

# Authenticate to Azure
Connect-AzAccount

# Start logging with transcript to capture all output
Start-Transcript -Path $LogFilePath -Append

# Get all subscriptions under the specified management group and select only the Name and DisplayName
$subscriptions = Get-AzManagementGroupSubscription -GroupId $TopLevelMgmtGrp | 
                 Select-Object -Property Name, DisplayName

# Define a script block to process each VM
$processVMBlock = {
    param($subscriptionId, $vm)

    Set-AzContext -SubscriptionId $subscriptionId

    try {
        $vmStatus = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
        $initialState = $vmStatus.Statuses[1].DisplayStatus
        $osType = $vm.StorageProfile.OsDisk.OsType
        Write-Output "Processing VM: $($vm.Name), Initial State: $initialState, OS Type: $osType"

        # Start VM if it is deallocated or stopped
        $vmStarted = $false
        if ($initialState -in @("VM deallocated", "VM stopped")) {
            Write-Output "Starting VM $($vm.Name)..."
            Start-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName
            $vmStarted = $true
        }

        # Determine the correct extension name based on OS type
        $extensionName = if ($osType -eq "Windows") { "MicrosoftMonitoringAgent" } else { "OmsAgentForLinux" }

        # Check if the extension is installed
        $installedExtensions = Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -ErrorAction SilentlyContinue
        $isExtensionInstalled = $installedExtensions | Where-Object { $_.Name -eq $extensionName }

        if ($isExtensionInstalled) {
            Write-Output "$extensionName is installed on VM $($vm.Name). Proceeding with uninstallation..."

            # Uninstall MMA or OMSAgentForLinux
            $result = Remove-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -Name $extensionName -Force -AsJob

            # Wait for the job to complete
            $result | Wait-Job | Out-Null

            Write-Output "Successfully uninstalled $extensionName from VM $($vm.Name)."
        } else {
            Write-Output "$extensionName is not installed on VM $($vm.Name). Skipping uninstallation."
        }

        # Shutdown the VM after uninstall if it was started by this script
        if ($vmStarted) {
            Write-Output "Stopping VM $($vm.Name)..."
            Stop-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Force
        }

        Write-Output "Completed processing VM $($vm.Name)."
    } catch {
        Write-Output "Error processing VM $($vm.Name): $_"
    }
}

# Process each subscription
foreach ($subscription in $subscriptions) {
    Set-AzContext -SubscriptionId $subscription.Name  # $subscription.Name is the SubscriptionId

    # Retrieve VMs for the current subscription
    $vms = Get-AzVM
    $parallelism = [math]::Min($vms.Count, 20)  # Adjust parallelism dynamically based on VM count, max 20

    # Process each VM in parallel
    $vms | ForEach-Object -ThrottleLimit $parallelism -Parallel $processVMBlock -ArgumentList $subscription.Name
}

# Stop the logging transcript
Stop-Transcript
