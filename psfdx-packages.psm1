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
function New-SalesforcePackageVersion {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)][string] $PackageId,        
        [Parameter(Mandatory = $false)][string] $PackageName,        
        [Parameter(Mandatory = $true)][string] $DevHubUsername,

        [Parameter(Mandatory = $false)][string] $Name,
        [Parameter(Mandatory = $false)][string] $Description,
        [Parameter(Mandatory = $false)][string] $Tag,

        [Parameter(Mandatory = $false)][string] $InstallationKey,
        [Parameter(Mandatory = $false)][switch] $InstallationKeyBypass,
        [Parameter(Mandatory = $false)][switch] $CodeCoverage,
        [Parameter(Mandatory = $false)][switch] $SkipValidation,

        [Parameter(Mandatory = $false)][int] $WaitMinutes,
        [Parameter(Mandatory = $false)][string] $ScratchOrgDefinitionFile = "config/project-scratch-def.json"
    ) 

    if ((! $PackageId ) -and (! $PackageName) ) {
        throw "Please provide a PackageId or Package Name"
    }
    if ((! $PackageId ) -and ($PackageName) ) {        
        $package = Get-SalesforcePackage -Name $PackageName -DevHubUsername $DevHubUsername                      
        $PackageId = $package.Id        
    }

    $command += "sfdx force:package:version:create --package $PackageId"
    if ($Name) {
        $command += " --versionname $Name"
    }
    if ($Description) {
        $command += " --versiondescription $Description"
    }    
    if ($Tag) {
        $command += " --tag $Tag"
    }
    if ($CodeCoverage) {
        $command += " --codecoverage"
    }    
    $command += " --definitionfile $ScratchOrgDefinitionFile"    

    if (($InstallationKeyBypass) -or (! $InstallationKey)) {
        $command += " --installationkeybypass"
    }
    else {        
        $command += " --installationkey $InstallationKey"
    }

    if ($SkipValidation) {
        $command += " --skipvalidation"
    }
    if ($WaitMinutes) {
        $command += " --wait $WaitMinutes"
    }
    
    Invoke-Sfdx -Command $command
}

function Get-SalesforcePackageVersions {
    [CmdletBinding()]
    Param(        
        [Parameter(Mandatory = $false)][string] $PackageId,        
        [Parameter(Mandatory = $false)][string] $PackageName,  

        [Parameter(Mandatory = $true)][string] $DevHubUsername,
        [Parameter(Mandatory = $false)][switch] $Released,
        [Parameter(Mandatory = $false)][switch] $Concise,
        [Parameter(Mandatory = $false)][switch] $ExtendedDetails
    )
    if ((! $PackageId ) -and ($PackageName) ) {        
        $package = Get-SalesforcePackage -Name $PackageName -DevHubUsername $DevHubUsername                      
        $PackageId = $package.Id        
    }    

    $command = "sfdx force:package:version:list"
    $command += " --targetdevhubusername $DevHubUsername"
    if ($PackageId) {
        $command += " --packages $PackageId"
    }
    if ($Released) {
        $command += " --released"
    }
    if ($Concise) {
        $command += " --concise"
    }
    if ($ExtendedDetails) {
        $command += " --verbose"
    }
    $command += " --json"

    $result = Invoke-Sfdx -Command $command    
    return Show-SfdxResult -Result $result
}

function Promote-SalesforcePackageVersion {
    [CmdletBinding()]
    Param(        
        [Parameter(Mandatory = $true)][string] $PackageVersionId,                
        [Parameter(Mandatory = $true)][string] $DevHubUsername,
        [Parameter(Mandatory = $false)][switch] $NoPrompt
    ) 

    $command = "sfdx force:package:version:promote"
    $command += " --package $PackageVersionId"
    $command += " --targetdevhubusername $DevHubUsername"
    if ($NoPrompt) {
        $command += " --noprompt"
    }
    $command += " --json"

    $result = Invoke-Sfdx -Command $command    
    return Show-SfdxResult -Result $result
}

function Remove-SalesforcePackageVersion {
    [CmdletBinding()]
    Param(        
        [Parameter(Mandatory = $true)][string] $PackageVersionId,                
        [Parameter(Mandatory = $true)][string] $DevHubUsername,
        [Parameter(Mandatory = $false)][switch] $NoPrompt
    ) 

    $command = "sfdx force:package:version:delete"
    $command += " --package $PackageVersionId"
    $command += " --targetdevhubusername $DevHubUsername"
    if ($NoPrompt) {
        $command += " --noprompt"
    }
    $command += " --json"

    $result = Invoke-Sfdx -Command $command    
    return Show-SfdxResult -Result $result
}

Export-ModuleMember Get-SalesforcePackages
Export-ModuleMember Get-SalesforcePackage
Export-ModuleMember New-SalesforcePackage
Export-ModuleMember Remove-SalesforcePackage

Export-ModuleMember Get-SalesforcePackageVersions
Export-ModuleMember New-SalesforcePackageVersion
Export-ModuleMember Promote-SalesforcePackageVersion
Export-ModuleMember Remove-SalesforcePackageVersion