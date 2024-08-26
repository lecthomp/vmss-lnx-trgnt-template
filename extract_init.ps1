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
    $policyDefinition = Get-AzPolicyDefinition -Id $policy.PolicyDefinitionId
    
    # Extract relevant details
    $policyName = $policyDefinition.Properties.DisplayName
    $policyVersion = $policyDefinition.Properties.PolicyDefinitionVersion
    $policyCategory = $policyDefinition.Properties.Metadata.Category
    $policyEffect = $policyDefinition.Properties.PolicyRule.If.Effect
    
    # Extract policy parameters
    $parameters = @()
    if ($policyDefinition.Properties.Parameters) {
        foreach ($param in $policyDefinition.Properties.Parameters.Keys) {
            $paramDetails = @{
                Name = $param
                Type = $policyDefinition.Properties.Parameters[$param].Type
                DefaultValue = $policyDefinition.Properties.Parameters[$param].DefaultValue
            }
            $parameters += $paramDetails
        }
    }

    # Store the collected data
    $policyDetails += [PSCustomObject]@{
        Name       = $policyName
        Version    = $policyVersion
        Category   = $policyCategory
        Effect     = $policyEffect
        Parameters = $parameters
    }
}

# Output the collected policy details
$policyDetails | Format-Table -AutoSize

# Optional: Export to CSV if needed
# $policyDetails | Export-Csv -Path "NIST_SP_800-53_Policies.csv" -NoTypeInformation
