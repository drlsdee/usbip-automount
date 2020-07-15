function Get-UsbIds {
    [CmdletBinding()]
    param(
        # URI
        [Parameter()]
        [uri]
        $DefaultUri = 'http://www.linux-usb.org/usb.ids',

        # Path to the folder containing USBIP executable
        [Parameter()]
        [string]
        $PathToUsbIp,

        # Update anyway
        [Parameter()]
        [switch]
        $Update
    )
    [string]$myName = "$($MyInvocation.MyCommand.Name):"
    Write-Verbose "$myName Get current location"
    [string]$locationCurrent = [System.IO.Directory]::GetCurrentDirectory()
    
    Write-Verbose "$myName Current location is: $locationCurrent"
    [string]$usbIds = 'usb.ids'

    Write-Verbose "$myName Search file $usbIds"

    if ($PathToUsbIp) {
        Write-Verbose "$myname Path to the folder containing `'usbip.exe`' is: $PathToUsbIp"
        [string]$locationTarget = [System.IO.Path]::Combine($PathToUsbIp, $usbIds)
    }
    else {
        [string]$locationTarget = [System.IO.Path]::Combine($locationCurrent, $usbIds)
    }
    [string]$locationBackup = [System.IO.Path]::ChangeExtension($locationTarget, 'bak')

    if (
        ([System.IO.File]::Exists($locationTarget)) -and `
        (-not $Update)
    )
    {
        Write-Verbose -Message "$myName The file `'$usbIds`' found in location: $locationTarget"
        return $true
    }

    [string]$tempFolder = [System.IO.Path]::GetTempPath()
    [string]$tempPath = [System.IO.Path]::Combine($tempFolder, $usbIds)

    Write-Verbose "$myName Trying to download file to temp path: $tempPath"
    $webClient = [System.Net.WebClient]::new()
    try {
        $webClient.DownloadFile($DefaultUri, $tempPath)
        Write-Verbose -Message "$myName The file was downloaded from $DefaultUri to $tempPath"
    }
    catch {
        Write-Warning -Message "$myName $($_.Exception.Message)"
        return $false
    }

    if ([System.IO.File]::Exists($locationTarget)) {
        Write-Verbose -Message "$myName Backing up old data to the file `'$locationBackup`'..."
        [System.IO.File]::Move($locationTarget, $locationBackup)
    }

    Write-Verbose -Message "$myName Moving the file from `'$tempPath`' to the target location `'$locationTarget`'..."
    
    [System.IO.File]::Move($tempPath, $locationTarget)

    if (-not [System.IO.File]::Exists($locationTarget)) {
        Write-Warning -Message "$myName The file $usbIds was not moved to `'$locationTarget`'! Exiting."
        return $false
    }

    Write-Verbose -Message "$myName The file $usbIds successfully updated. Removing backup and exiting."
    [System.IO.File]::Delete($locationBackup)
    return $true
}