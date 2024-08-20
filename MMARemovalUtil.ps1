   # Authenticate to Azure
	Connect-AzAccount
 

	# Path to the log file
	$logFile = "C:\Users\PVarma\Downloads\MMA_Removal_log2.txt"
	
	# Function to log messages
	function Write-Log {
    	param($message)
    	Add-Content -Path $logFile -Value "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"): $message"
	}


    #Pull Sub's from a Top Level Managment Group

    $topLvlMgmtGrp = "MGMT-00-PR-TEST"          # Name of the top level management group
    $subscriptions = @()                                # Output array

    # Collect data from managementgroups
    $mgmtGroups = Get-AzManagementGroup -GroupId $topLvlMgmtGrp -Expand -Recurse

    $children = $true
    while ($children) {
    $children = $false
    $firstrun = $true
    foreach ($entry in $mgmtGroups) {
        if ($firstrun) {Clear-Variable mgmtGroups ; $firstrun = $false}
        if ($entry.Children.length -gt 0) {
            # Add management group to data that is being looped throught
            $children       = $true
            $mgmtGroups    += $entry.Children
        }
        elseif ($entry.type -ne "Microsoft.Management/managementGroups") {
            # Add subscription to output object
            $subscriptions += New-Object -TypeName psobject -Property ([ordered]@{'DisplayName'=$entry.DisplayName;'SubscriptionID'=$entry.Name})
                }
            }
        }

        #$subscriptions


         foreach ($subscription in $subscriptions) {
         $count = 0
         $count++
         $subscription

   	    #Set-AzContext -Subscription $subscription.DisplayName
        Set-AzContext -SubscriptionId $subscription.SubscriptionId

    	# Retrieve VMs for the current subscription
    	$vms = Get-AzVM
 	    $count = 0
 
        # Process each VM in the list
        foreach ($vm in $vms) {
        $count++
        Write-Host "Processing $($count) of $(($vms).count)"
        $vm.Name


        $vmStarted = $false
        try {
        # Get the VM status and properties
        $vmStatus = Get-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Status
        #$vmInfo = Get-AzVM -Name $vm.ComputerName -ResourceGroupName $vm."Resource Group"
        Write-Log "VM $($vm.Name): Status: $($vmStatus.Statuses[1].DisplayStatus), OS Type: $($vm.StorageProfile.OsDisk.OsType)"
        
        # Start VM if it is deallocated or stopped
        if ($vmStatus.Statuses[1].DisplayStatus -eq "VM deallocated" -or $vmStatus.Statuses[1].DisplayStatus -eq "VM stopped") {
            Write-Log "Starting VM $($vm.Name) as it is deallocated or stopped.)"
            Start-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName
            $vmStarted = $true
        }
        #uninstall MMA or OMSAgentforLinux
        if ($vm.StorageProfile.OsDisk.OsType -eq "Windows") {
            Write-Log "Uninstalling MicrosoftMonitoringAgent on VM $($vm.Name)."
            $result = Remove-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -Name MicrosoftMonitoringAgent -Force -AsJob
            $result = Remove-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -Name MMAExtension -Force -AsJob
            If($result.IsSuccessStatusCode)
            {
                Write-Log "Successfully uninstalled MMA on VM $($vm.Name)"
            }
           }
           else
           {
                Write-Log "Uninstalling OmsAgentForLinux on VM $($vm.Name)."
                $result = Remove-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -Name OMSAgentForLinux -Force -AsJob
                If($result.IsSuccessStatusCode)
                {
                Write-Log "Successfully uninstalled OmsAgentForLinux on VM $($vm.Name)"
                }
           }
        # Shutdown the VM after uninstall only if it was started by this script
        if ($vmStarted) {
            Write-Log "Shutting down VM $($vm.Name) after agent uninstall as it was initially deallocated or stopped."
            Stop-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Force
        } else {
            Write-Log "Leaving VM $($vm.Name) running as it was already running before script execution."
        }
        # Log successful completion
        Write-Log "Completed operations successfully for VM $($vm.Name)."
        } 
        catch 
        {
        # Log any exceptions
        Write-Log "Error occurred with VM $($vm.Name): $_"
        }
        }
        }
