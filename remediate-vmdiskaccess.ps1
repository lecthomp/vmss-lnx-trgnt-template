param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ManagementGroupName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$LogFilePath
)

function Log-Message {
    param (
        [string]$Message,
        [string]$Type = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$($timestamp)] [$($Type)] $($Message)"
    Add-Content -Path $LogFilePath -Value $logMessage
}

# Authenticate with Azure
Log-Message "Authenticating to Azure..."
try {
    Connect-AzAccount -ErrorAction Stop
    Log-Message "Authentication successful."
} catch {
    Log-Message "Failed to authenticate to Azure: $_" -Type "ERROR"
    exit 1
}

Log-Message "Fetching active subscriptions under management group $ManagementGroupName..."
try {
    $subscriptions = Get-AzManagementGroupSubscription -GroupName $ManagementGroupName | 
                     Where-Object { $_.State -eq "Active" } | 
                     Select-Object -Property DisplayName, @{Name="SubscriptionId"; Expression={($_.Id -split "/")[-1]}}
    
    Log-Message "Found $($subscriptions.Count) active subscriptions under management group $ManagementGroupName."
} catch {
    Log-Message "Failed to retrieve subscriptions for management group $ManagementGroupName: $_" -Type "ERROR"
    exit 1
}

# Define the script block for parallel processing
$scriptBlock = {
    param ($subscriptionId, $logFilePath)

    # Import required modules in parallel tasks if necessary
    #Import-Module Az.Compute
    #Import-Module Az.Resources

    # Function to log messages in parallel
    function Log-Message {
        param (
            [string]$Message,
            [string]$Type = "INFO"
        )
    
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$($timestamp)] [$($Type)] $($Message)"
        Add-Content -Path $logFilePath -Value $logMessage
    }

    
    try {
        Set-AzContext -SubscriptionId $subscriptionId -ErrorAction Stop
        Log-Message "Processing subscription: $subscriptionId"
    } catch {
        Log-Message "Failed to set context for subscription $subscriptionId: $_" -Type "ERROR"
        return
    }

    
    try {
        $resourceGroups = Get-AzResourceGroup -ErrorAction Stop
    } catch {
        Log-Message "Failed to retrieve resource groups for subscription $subscriptionId: $_" -Type "ERROR"
        return
    }

    foreach ($rg in $resourceGroups) {
        try {
            $vms = Get-AzVM -ResourceGroupName $rg.ResourceGroupName -ErrorAction Stop
        } catch {
            Log-Message "Failed to retrieve VMs for resource group $($rg.ResourceGroupName) in subscription $subscriptionId: $_" -Type "ERROR"
            continue
        }

        foreach ($vm in $vms) {
            # Get the VM's OS disk and any attached data disks
            $vmDisks = @($vm.StorageProfile.OsDisk) + $vm.StorageProfile.DataDisks

            foreach ($disk in $vmDisks) {
                $diskName = $disk.ManagedDisk.Id.Split("/")[-1]
                $diskResourceGroup = $disk.ManagedDisk.Id.Split("/")[4]

                try {
                    $managedDisk = Get-AzDisk -ResourceGroupName $diskResourceGroup -DiskName $diskName -ErrorAction Stop

                    if (-not $managedDisk.ManagedBy) {
                        Log-Message "Skipping non-VM managed disk: $($managedDisk.Name) in resource group: $($diskResourceGroup) (no 'ManagedBy' property)."
                        continue
                    }

                } catch {
                    Log-Message "Failed to retrieve disk $diskName in resource group $diskResourceGroup for VM $($vm.Name) in subscription $subscriptionId: $_" -Type "ERROR"
                    continue
                }

                # Check the disk's network access policy
                if ($managedDisk.NetworkAccessPolicy -ne "DenyAll") {
                    Log-Message "Remediating disk: $($managedDisk.Name) on VM: $($vm.Name) in subscription $subscriptionId"
                    
                    try {
                        $managedDisk.NetworkAccessPolicy = "DenyAll"
                        Update-AzDisk -ResourceGroupName $diskResourceGroup -DiskName $managedDisk.Name -Disk $managedDisk -ErrorAction Stop
                        Log-Message "Network access for disk $($managedDisk.Name) has been set to DenyAll."
                    } catch {
                        Log-Message "Failed to update network access policy for disk $($managedDisk.Name) on VM $($vm.Name) in subscription $subscriptionId: $_" -Type "ERROR"
                    }
                } else {
                    Log-Message "Disk $($managedDisk.Name) on VM: $($vm.Name) in subscription $subscriptionId already has NetworkAccessPolicy set to DenyAll."
                }
            }
        }
    }
}

$subscriptions | ForEach-Object -Parallel {
    $using:scriptBlock.Invoke($_.SubscriptionId, $using:LogFilePath)
} -ThrottleLimit 10

Log-Message "Script completed."
