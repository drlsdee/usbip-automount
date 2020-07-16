function Initialize-UsbIp {
    [CmdletBinding()]
    param (
        # Path to the USBIP distributive folder
        [Parameter()]
        [string]
        $Path,

        # Target version (now default is 0.2.0.0)
        [Parameter()]
        [version]
        $Version = 0.2.0.0
    )
    [LogStamp]$timeStamp = [LogStamp]::new([System.String]$MyInvocation.InvocationName)
    Write-Verbose -Message $timeStamp.GetStamp('Starting the function...')
    <#
        Checking the following conditions:
        0.  The distributive folder contains all needed files.
        1.  The signer's certificate is present in 'TrustedPublisher' store on the local machine.
        2.  The drivers are installed vith version greater or equal to defined version.
        3.  The executable file 'usbip.exe' is present in one or more of default paths.
        4.  The executable file 'usbip.exe' is patched.
        5.  The list of USB devices 'usb.ids' is present either in the current working directory or besides the executable file 'usbip.exe' and is up to date.
    #>

    [bool]$distResult                   = Find-UsbIpDistributive -Path $Path
    [bool]$certResult                   = Get-UsbIpCertificate -Path $Path
    [bool]$drvResult                    = Find-UsbIpDrivers -Version $Version

    [string[]]$usbIpExePathsExisting    = Find-FileInEnvPath -FileName 'usbip.exe'
    if ($usbIpExePathsExisting)
    {
        [bool]$pathResult               = $true
        [string]$usbIpFilePath          = $usbIpExePathsExisting[0]
        [string]$usbIpWorkDir           = [System.IO.Path]::GetDirectoryName($usbIpFilePath)
    }
    else {
        [bool]$pathResult               = $false
        [string]$usbIpWorkDir           = $env:SystemRoot
        [string]$usbIpFilePath          = [System.IO.Path]::Combine($usbIpWorkDir, 'usbip.exe')
    }
    [string]$usbIdsPath                 = [System.IO.Path]::Combine($usbIpWorkDir, 'usb.ids')

    [bool]$usbIdsResult                 = [System.IO.File]::Exists($usbIdsPath)

    [bool]$filePatchResult              = Update-UsbIpExe -Path $usbIpFilePath

    switch ($true) {
        $distResult         { "Distro exists!" }
        $certResult         { "Certificate installed!" }
        $drvResult          { "Drivers are present!" }
        $pathResult         { "Executable file 'usbip.exe' found!" }
        $filePatchResult    { "Executable file 'usbip.exe' patched!" }
        $usbIdsResult       { "File 'usb.ids' found!" }
        Default {}
    }
    [UsbIpExe]$usbIpExe = [UsbIpExe]::new($usbIpWorkDir)
    $usbIpExe.StartProcess('-h')
}
