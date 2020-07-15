function Initialize-UsbIp {
    [CmdletBinding()]
    param (
        # Path to the USBIP distributive folder
        [Parameter()]
        [string]
        $Path
    )
    [LogStamp]$timeStamp = [LogStamp]::new([System.String]$MyInvocation.InvocationName)
    Write-Verbose -Message $timeStamp.GetStamp('Starting the function...')
    if (-not [System.IO.Directory]::Exists($Path)) {
        Write-Warning -Message $timeStamp.GetStamp("The folder `'$Path`' does not exist! Exiting.")
        return
    }
<# 
    [string[]]$filesMustPresent = @(
        'USAGE',
        'usb.ids',
        'usbip.exe',
        'usbipenum.cat',
        'USBIPEnum.inf',
        'USBIPEnum_x64.sys',
        'USBIPEnum_x86.sys'
    ).ForEach({
        [System.IO.Path]::Combine($Path, $_)
    })
#>
    [string]$infFile = [System.IO.Path]::Combine($Path, 'USBIPEnum.inf')
    [string[]]$exeFiles = @(
        'usb.ids',
        'usbip.exe'
    ).ForEach({
        [System.IO.Path]::Combine($Path, $_)
    })
    [string[]]$driverBinaries = @(
        'usbipenum.cat',
        'USBIPEnum_x64.sys',
        'USBIPEnum_x86.sys'
    ).ForEach({
        [System.IO.Path]::Combine($Path, $_)
    })

    [string[]]$filesFound = [System.IO.Directory]::EnumerateFiles($Path)
    if (-not $filesFound) {
        Write-Warning -Message $timeStamp.GetStamp("The folder `'$Path`' is empty! Exiting.")
        return
    }
    Write-Verbose -Message $timeStamp.GetStamp("Found $($filesFound.Count) files total in the folder `'$Path`'. Continue.")

    @(
        $driverBinaries + $exeFiles + $infFile
    ).ForEach({
        [string]$fileName = $_
        if (
            $fileName -notin $filesFound
        )
        {
            Write-Warning -Message $timeStamp.GetStamp("The file `'$fileName`' was not found in the folder `'$Path`'! Exiting.")
            exit
        }
        else {
            Write-Verbose -Message $timeStamp.GetStamp("The file `'$fileName`' found in the folder `'$Path`'.")
        }
    })

    [string[]]$infContentRaw = [System.IO.File]::ReadLines($infFile).Where({
        (-not [regex]::IsMatch($_, '^;')) -and `
        (-not [string]::IsNullOrEmpty($_)) -and `
        (-not [string]::IsNullOrWhiteSpace($_))
    })
}