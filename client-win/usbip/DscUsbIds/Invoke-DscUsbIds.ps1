function Invoke-DscUsbIds {
    [CmdletBinding()]
    param (
        # Source path
        [Parameter(
            Mandatory           = $true,
            ParameterSetName    = 'Path'
        )]
        [string]
        $Path,

        # Source URI
        [Parameter(
            ParameterSetName    = 'Uri'
        )]
        [uri]
        $Uri = 'http://www.linux-usb.org/usb.ids',

        # Destination path
        [Parameter(
            Mandatory           = $true
        )]
        [string]
        $Destination,

        # Ensure
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [string]
        $Ensure = 'Present',

        # Method
        [Parameter()]
        [ValidateSet('Get', 'Set', 'Test')]
        [string]
        $Method,

        # Path to the module
        [Parameter()]
        [string]
        $ModulePath
    )
    [string]$myName = "$($MyInvocation.InvocationName):"
    Write-Verbose -Message "$myName Starting function..."

    if (-not $ModulePath) {
        #Get-Module -Name $PSScriptRoot -ListAvailable
        [string[]]$moduleManifestList = [System.IO.Directory]::EnumerateFiles($PSScriptRoot, '*.psd1')
        [string[]]$moduleScriptList = [System.IO.Directory]::EnumerateFiles($PSScriptRoot, '*.psm1')
        [string[]]$moduleScriptsToLoad = $moduleScriptList.Where({
            [System.IO.Path]::ChangeExtension($_, 'psd1') -notin $moduleManifestList
        })
        [string[]]$modulesToLoad = $moduleManifestList + $moduleScriptsToLoad
    }
    else {
        [string[]]$modulesToLoad += $ModulePath
    }
    [string[]]$modulesToUnload = $modulesToLoad.ForEach({
        [System.IO.Path]::GetFileNameWithoutExtension($_)
    })

    $modulesToLoad.ForEach({
        Write-Verbose -Message "$myName Loading module: $_"
        Import-Module -Name $_ -Force
    })

    Write-Verbose -Message "$myName Creating an object of type [DscUsbIds]..."
    [DscUsbIds]$dscUsbIds = [DscUsbIds]::new()
    if ($Path) {
        Write-Verbose -Message "$myName Source path: $Path"
        $dscUsbIds.SourcePath = $Path
    }
    else {
        Write-Verbose -Message "$myName Source URI: $Uri"
        $dscUsbIds.SourceUri = $Uri
    }

    Write-Verbose -Message "$myName Destination folder: $Destination"
    $dscUsbIds.DestinationFolder = $Destination
    Write-Verbose -Message "$myName Desired state: $Ensure"
    $dscUsbIds.Ensure = $Ensure

    Write-Verbose -Message "$myName Calling the method: $Method"
    switch ($Method) {
        'Get'   {
            $dscUsbIds.Get()
        }
        'Set'   {
            $dscUsbIds.Set()
        }
        'Test'  {
            $dscUsbIds.Test()
        }
        Default {
            Write-Verbose -Message "$myName Method was not defined. Calling the method `'Get()`'..."
            $dscUsbIds.Get()
        }
    }

    $modulesToUnload.ForEach({
        Write-Verbose -Message "$myName Unloading the module: $_"
        Remove-Module -Name $_ -Force
    })

    Write-Verbose -Message "$myName End of the function."
    return
}
