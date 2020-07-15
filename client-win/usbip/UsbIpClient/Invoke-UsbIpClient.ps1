param (
    [Parameter()]
    [scriptblock]
    $ScriptBlock
)
<#
.SYNOPSIS
    The function just loads the PowerShell module from the folder in which it is located, launches the script block and unloads the module.
.DESCRIPTION
    The function just loads the PowerShell module from the folder in which it is located, launches the script block and unloads the module.
.EXAMPLE
    PS C:\> Invoke-UsbIpClient
    It will load the module? show the module info and unload the module.
.INPUTS
    [System.Management.Automation.ScriptBlock]
.OUTPUTS
    Output depends on your scriptblock
.NOTES
    General notes
#>
function Invoke-UsbIpClient {
    [CmdletBinding()]
    param (
        # List your commands here
        [Parameter()]
        [scriptblock]
        $ScriptBlock
    )
    [string]$msgPrefix = "$($MyInvocation.InvocationName):"
    # Get the module name
    [string]$moduleName = [System.IO.Path]::GetFileName($PSScriptRoot)
    Write-Verbose -Message "$msgPrefix Starting function on the module: $moduleName"
    # Enumerate all module files
    [string]$moduleScript = [System.IO.Path]::Combine($PSScriptRoot, "$($moduleName).psm1")
    [string]$moduleManifest = [System.IO.Path]::Combine($PSScriptRoot, "$($moduleName).psd1")

    if  (
        (-not [System.IO.File]::Exists($moduleManifest)) -and `
        (-not [System.IO.File]::Exists($moduleScript))
    )
    {
        Write-Warning -Message "$msgPrefix Module files not found! Exiting."
        return
    }

    if  ([System.IO.File]::Exists($moduleManifest))
    {
        Write-Verbose -Message "$msgPrefix Importing the manifest: $moduleManifest"
        Import-Module -Name $moduleManifest -Force
    }
    else
    {
        Write-Verbose -Message "$msgPrefix Importing the script module: $moduleScript"
        Import-Module -Name $moduleScript -Force
    }
    
    # Do something here
    if (-not $ScriptBlock) {
        Write-Verbose -Message "$msgPrefix Scriptblock is not defined. Just get the module info: Get-Module -Name $moduleName"
        $ScriptBlock = [scriptblock]::Create("Get-Module -Name $moduleName | Format-List")
    }
    Write-Verbose -Message "$msgPrefix Starting scriptblock..."
    $ScriptBlock.Invoke()

    # Unload
    Write-Verbose -Message "$msgPrefix Unloading the module: $moduleName"
    Remove-Module -Name $moduleName -Force
    Write-Verbose -Message "$msgPrefix End of function."
    return
}

Invoke-UsbIpClient -ScriptBlock {
    #Invoke-UsbIp -Verbose #-Path 'C:\usbip1\usbip.exe'
    Initialize-UsbIp -Verbose -Path '\\srv-1c-00\c$\usbip'
} -Verbose
