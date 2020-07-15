function Invoke-UsbIp {
    [CmdletBinding()]
    param (
        # Path to the USBIP executable file
        [Parameter()]
        [string]
        $Path,

        # List hosts
        [Parameter(
            ParameterSetName    = 'List'
        )]
        [switch]
        $List,

        # Hostnames
        [Parameter(
            Mandatory           = $true,
            ParameterSetName    = 'List'
        )]
        [string[]]
        $ComputerName,

        # Vendor name masks
        [Parameter(
            ParameterSetName    = 'List'
        )]
        [string[]]
        $VendorName,

        # Device name masks
        [Parameter(
            ParameterSetName    = 'List'
        )]
        [string[]]
        $DeviceName
    )
    [LogStamp]$timeStamp = [LogStamp]::new([System.String]$MyInvocation.InvocationName)
    Write-Verbose -Message $timeStamp.GetStamp('Starting the function...')
    
    [string[]]$pathsDefault = Find-FileInEnvPath -FileName 'usbip.exe'
    if  (
        (-not $Path) -and `
        (-not $pathsDefault)
    )
    {
        Write-Warning -Message $timeStamp.GetStamp("Path to the file `'usbip.exe`' was neither specified in bound parameters nor found in default locations! Exiting.")
        return
    }
    elseif  (
        -not $Path
    )
    {
        [string]$usbIpFilePath = $pathsDefault[0]
        Write-Verbose -Message $timeStamp.GetStamp("Path to the file `'usbip.exe`' was found in default location: $usbIpFilePath")
    }
    else
    {
        [string]$usbIpFilePath = [System.IO.Path]::GetFullPath($Path)
        Write-Verbose -Message $timeStamp.GetStamp("Path to the file `'usbip.exe`' was defined explicitly: $usbIpFilePath")
    }

    if (-not [System.IO.File]::Exists($usbIpFilePath)) {
        Write-Warning -Message $timeStamp.GetStamp("The file `'$usbIpFilePath`' does not exist! Exiting.")
        return
    }

    [string]$usbIpFolderPath = [System.IO.Path]::GetDirectoryName($usbIpFilePath)
    Write-Verbose -Message $timeStamp.GetStamp("Path to the folder containing the file `'usbip.exe`': $usbIpFolderPath")

    Write-Verbose -Message $timeStamp.GetStamp("Creating an object for the file `'usbip.exe`': $usbIpFilePath")
    [UsbIpExe]$usbIpExe = [UsbIpExe]::new($usbIpFolderPath)
}