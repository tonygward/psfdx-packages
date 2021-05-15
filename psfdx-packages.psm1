function Invoke-Sfdx {
    [CmdletBinding()]
    Param([Parameter(Mandatory = $true)][string] $Command)        
    Write-Verbose $Command
    return Invoke-Expression -Command $Command
}

function Show-SfdxResult {
    [CmdletBinding()]
    Param([Parameter(Mandatory = $true)][psobject] $Result)           
    $result = $Result | ConvertFrom-Json
    if ($result.status -ne 0) {
        Write-Debug $result
        throw ($result.message)
    }
    return $result.result
}

function Get-SalesforcePackages {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][string] $DevHubUsername,        
        [Parameter(Mandatory = $false)][switch] $IncludeExtendedPackageDetails
    )   
    $command = "sfdx force:package:list --targetdevhubusername $DevHubUsername"
    if ($IncludeExtendedPackageDetails) {
        $command += " --verbose"
    }
    $command += " --json"
    $result = Invoke-Sfdx -Command $command 
    return Show-SfdxResult -Result $result
}

function Get-SalesforcePackage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $DevHubUsername,
        [Parameter(Mandatory = $false)][switch] $IncludeExtendedPackageDetails
    )   
    $packages = Get-SalesforcePackages -DevHubUsername $DevHubUsername -IncludeExtendedPackageDetails:$IncludeExtendedPackageDetails
    return $packages | Where-Object Name -eq $Name    
}

function New-SalesforcePackage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $DevHubUsername,
        [Parameter(Mandatory = $false)][string][ValidateSet("Managed", "Unlocked")] $PackageType,
        [Parameter(Mandatory = $false)][switch] $IsOrgDependent,
        [Parameter(Mandatory = $false)][string] $Path = "force-app/main/default",
        [Parameter(Mandatory = $false)][string] $Description,
        [Parameter(Mandatory = $false)][switch] $NoNamespace
    )   
    if (! $Description) {
        $Description = $Name
    }
    $command = "sfdx force:package:create --name $Name --description $Description" 
    $command += " --path $Path"  
    $command += " --packagetype $PackageType"
    if ($IsOrgDependent) {
        $command += " --orgdependent"
    }
    if ($NoNamespace) {
        $command += " --nonamespace"
    }
    $command += " --targetdevhubusername $DevHubUsername"
    $command += " --json"
    $result = Invoke-Sfdx -Command $command
    $resultSfdx = Show-SfdxResult -Result $result
    return $resultSfdx.Id
}

function Remove-SalesforcePackage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $DevHubUsername,
        [Parameter(Mandatory = $false)][switch] $NoPrompt
    ) 
    $command = "sfdx force:package:delete --package $Name"
    if ($NoPrompt) {
        $command += " --noprompt"
    }
    $command += " --targetdevhubusername $DevHubUsername"
    Invoke-Sfdx -Command $command
}  

Export-ModuleMember Get-SalesforcePackages
Export-ModuleMember Get-SalesforcePackage
Export-ModuleMember New-SalesforcePackage
Export-ModuleMember Remove-SalesforcePackage