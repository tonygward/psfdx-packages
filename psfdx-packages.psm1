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

Export-ModuleMember Get-SalesforcePackages
Export-ModuleMember Get-SalesforcePackage