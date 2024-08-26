# Ensure you're logged in to Azure
Connect-AzAccount

# Set the Policy Initiative Definition ID
$initiativeId = "/providers/Microsoft.Authorization/policySetDefinitions/179d1daa-458f-4e47-8086-2a68d0d6c38f"

# Retrieve the Policy Initiative using the Definition ID
$initiative = Get-AzPolicySetDefinition -Id $initiativeId

if ($initiative -eq $null) {
    Write-Host "Policy Initiative not found!"
    exit
}

# Initialize an array to store policy details
$policyDetails = @()

# Iterate through each policy definition within the initiative
foreach ($policy in $initiative.Properties.PolicyDefinitions) {
    
    # Get the full policy definition using the policy ID
    Write-Host $policy.PolicyDefinitionId
    $policyDefinition = Get-AzPolicyDefinition -Id $policy.PolicyDefinitionId
    Write-Host $policyDefinition
    # Extract relevant details
    $policyName = $policyDefinition.Properties.DisplayName
    $policyDescription = $policyDefinition.Properties.Description
    $policyVersion = $policyDefinition.Properties.Metadata.version
    $policyCategory = $policyDefinition.Properties.Metadata.Category
    $policyEffect = $policyDefinition.Properties.Parameters.effect.allowedValues
    $policyDefaultEffect = $policyDefinition.Properties.Parameters.effect.defaultValue
    $policyParameter = $policyDefinition.Properties.Parameters.effect.metadata.description
    

    # Store the collected data
    $policyDetails += [PSCustomObject]@{
        Name       = $policyName
        Version    = $policyVersion
        Category   = $policyCategory
        Effect     = $policyEffect
        DefaultEffect = $policyDefaultEffect
        Parameter = $policyParameter
    }
}

# Output the collected policy details
$policyDetails | Format-Table -AutoSize

# Optional: Export to CSV if needed
 $policyDetails | Export-Csv -Path "NIST_SP_800-53_Policies.csv" -NoTypeInformation
