function Get-UsbIds {
    [CmdletBinding()]
    param(
        [uri]
        $locationDefault = 'http://www.linux-usb.org/usb.ids',

        [string]
        $locationOnfileSystem
    )
    [string]$myName = "$($MyInvocation.MyCommand.Name):"
    Write-Verbose "$myName Get current location"
    [string]$locationCurrent = [System.IO.Directory]::GetCurrentDirectory()
    Write-Verbose "Current location is: $locationCurrent"

    Write-Verbose "$myName Search file usb.ids"
    [string]$filePath = "$($locationCurrent)\usb.ids"
    if (
        [System.IO.File]::Exists($filePath)
    )
    {
        Write-Verbose "$myName Exists: $filePath"
        return
    }

    Write-Verbose "$myName Trying to download file"
    $webClient = [System.Net.WebClient]::new()
    try {
        $webClient.DownloadFile($locationDefault, $filePath)
        Write-Verbose -Message "$myName The file was downloaded from $locationDefault to $filePath"
        return
    }
    catch {
        Write-Warning $_.Exception.Message
        return
    }
}