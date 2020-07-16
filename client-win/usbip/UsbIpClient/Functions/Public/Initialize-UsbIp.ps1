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
    [System.Management.Automation.ErrorRecord[]]$allErrors = @()
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

    switch ($false) {
        $distResult         {
            Write-Warning -Message $timeStamp.GetStamp("Distro does not exists!")
        }
        $certResult         {
            Write-Warning -Message $timeStamp.GetStamp("Certificate is not installed!")
            try {
                Get-UsbIpCertificate -Path $Path -Install
            }
            catch {
                Write-Verbose -Message  $timeStamp.GetStamp("Failed to install the certificate to the 'TrustedStore' location on the system `'$env:COMPUTERNAME`'!")
                $allErrors += $_
            }
        }
        $drvResult          {
            Write-Warning -Message $timeStamp.GetStamp("Drivers are not present!")
        }
        $pathResult         {
            Write-Warning -Message $timeStamp.GetStamp("Executable file 'usbip.exe' not found!")
            <# [string]$pathSrc    = [System.IO.Path]::Combine($Path, 'usbip.exe')
            [string]$pathDst    = [System.IO.Path]::Combine($usbIpWorkDir, 'usbip.exe')
            try {
                Write-Verbose -Message  $timeStamp.GetStamp("Copying the file `'$pathSrc`' to the destination `'$pathDst`'...")
                [System.IO.File]::Copy($pathSrc, $pathDst, $true)
            }
            catch {
                Write-Verbose -Message  $timeStamp.GetStamp("Failed to copy the file `'$pathSrc`' to the destination `'$pathDst`'!")
                $allErrors += $_
            } #>
            Invoke-DscResource -ModuleName UsbIpFilesExists -Method Get -Property @{
                DestinationPath = $usbIpFilePath
                SourcePath      = [System.IO.Path]::Combine($Path, 'usbip.exe')
                Ensure          = 'Present'
            }
        }
        $filePatchResult    {
            Write-Warning -Message $timeStamp.GetStamp("Executable file 'usbip.exe' not patched!")
        }
        $usbIdsResult       {
            Write-Warning -Message $timeStamp.GetStamp("File 'usb.ids' not found!")
            <# try {
                Write-Verbose -Message $timeStamp.GetStamp("Downloading file 'usb.ids' to the folder `'$usbIpWorkDir`'...")
                $usbIdsResult = Get-UsbIds -PathToUsbIp $usbIpWorkDir -Update
            }
            catch {
                Write-Verbose -Message  $timeStamp.GetStamp("Failed to copy the file 'usb.ids' to the destination `'$usbIpWorkDir`'!")
                $allErrors += $_
            } #>
        }
        Default             {
            [UsbIpExe]$usbIpExe = [UsbIpExe]::new($usbIpWorkDir)
            $usbIpExe.StartProcess('-h')
        }
    }

    if ($allErrors) {
        Write-Warning -Message $timeStamp.GetStamp("Errors were found! USBIP installation was probably failed. Returning errors and exiting.")
        return $allErrors
    }
}
