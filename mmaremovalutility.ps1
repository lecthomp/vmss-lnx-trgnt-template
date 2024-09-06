
param (
    [Parameter(Mandatory = $true)]
    [string]$TopLevelMgmtGrp,  # The top-level management group as a parameter

    [Parameter(Mandatory = $true)]
    [string]$LogFilePath  # Log file path as a parameter
)

# Authenticate to Azure default subscription (Cloud Governance)
Connect-AzAccount -Subscription 'd7335807-edc7-4972-846e-310e64f4053a'

# Start logging with transcript to capture all output
Start-Transcript -Path $LogFilePath -Append

# Get all subscriptions under the specified management group and select only the Name and DisplayName
$subscriptions = Get-AzManagementGroupSubscription -GroupName $TopLevelMgmtGrp | Where-Object {$_.State -eq "Active"} |
                 Select-Object -Property DisplayName, @{Name="SubscriptionId"; Expression={($_.Id -split "/")[-1]}}

# Use to test single subscription
#$subscriptions = 'i007-01-d1-spk-sub-001'

# Define a script block to process each VM
$processVMBlock = {
    param($subscriptionId, $vm)

    Set-AzContext -Subscription $subscriptionId #Make sure you're in the right subscription
    write-host $subscriptionId

    try {
        $vmStatus = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
        $initialState = $vmStatus.Statuses[1].DisplayStatus
        $vminfo = Get-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName 
        $osType = $vminfo.StorageProfile.OsDisk.OsType  #//| Select-Object -Property @{Expression={$_.StorageProfile.OsDisk.OsType}}
        Write-Output "Processing VM: $($vm.Name), Initial State: $initialState, OS Type: $osType"

        # Start VM if it is deallocated or stopped
        $vmStarted = $false
        if ($initialState -in @("VM deallocated", "VM stopped")) {
            Write-Output $os"Starting VM $($vm.Name)..."
            Start-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName
            $vmStarted = $true
        }

        # Determine the correct extension name based on OS type
        $extensionName = if ($osType -eq "Windows") {"MMAExtension", "MicrosoftMonitoringAgent"}  elseif ($osType -eq "Linux") { "OMSAgentForLinux" }

        # Check if the extension is installed
        $installedExtensions = Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name | Where-Object {$_.Name -eq "MMAExtension" -or $_.Name -eq "MicrosoftMonitoringAgent" -or $_.Name -eq "OMSAgentForLinux"} -ErrorAction SilentlyContinue
        $isExtensionInstalled = $installedExtensions | Where-Object { $_.Name -in $extensionName }

        if ($isExtensionInstalled.Name) {
            Write-Output "$extensionName is installed on VM $($vm.Name). Proceeding with uninstallation..."

            # Uninstall MMA or OMSAgentForLinux  
            #$result = Remove-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -Name $extensionName -Force -AsJob
            $result = Remove-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -Name $isExtensionInstalled.Name -Force -AsJob

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
        $errorDetails = $_ | Out-String
        Write-Output "Error processing VM $($vm.Name): $errorDetails"
    }
}

# Process each subscription
foreach ($subscription in $subscriptions) {
    Set-AzContext -Subscription $subscription.DisplayName  

    # Retrieve VMs for the current subscription
    $vms = Get-AzVM
    $jobs = @()


    foreach ($vm in $vms) {
        # Start a new background job for each VM
        $jobs += Start-Job -ScriptBlock $processVMBlock -ArgumentList $subscription.DisplayName, $vm
    }

    # Wait for all jobs to complete
    $jobs | ForEach-Object {
        $_ | Wait-Job
        $_ | Receive-Job
        Remove-Job $_
    }
}

# Stop the logging transcript
Stop-Transcript
