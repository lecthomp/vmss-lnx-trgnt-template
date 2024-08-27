# Ensure you're logged in to Azure
Connect-AzAccount

# Set the Policy Initiative Definition ID
$initiativeId = "/providers/Microsoft.Authorization/policySetDefinitions/c047ea8e-9c78-49b2-958b-37e56d291a44"

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
    $policyEffects = $policyDefinition.Properties.Parameters.effect.allowedValues
    $policyDefaultEffect = $policyDefinition.Properties.Parameters.effect.defaultValue
    $policyParameter = $policyDefinition.Properties.Parameters.effect.metadata.description
    $policyEffectString = $policyEffects -join ","
    

    # Store the collected data
    $policyDetails += [PSCustomObject]@{
        Name       = $policyName
        Version    = $policyVersion
        Category   = $policyCategory
        Effect     = $policyEffectString
        DefaultEffect = $policyDefaultEffect
        Parameter = $policyParameter
    }
}

# Output the collected policy details
$policyDetails | Format-Table -AutoSize

# Optional: Export to CSV if needed
 $policyDetails | Export-Csv -Path "NIST_SP_800-53_Policies.csv" -NoTypeInformation
