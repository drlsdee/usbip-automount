function Find-UsbIpDrivers {
    [CmdletBinding()]
    param (
        # Target version (now default is 0.2.0.0)
        [Parameter()]
        [version]
        $Version
    )
    [LogStamp]$timeStamp = [LogStamp]::new([System.String]$MyInvocation.InvocationName)
    Write-Verbose -Message $timeStamp.GetStamp('Starting the function...')
    try {
        Write-Verbose -Message $timeStamp.GetStamp("Enumerating all drivers installed on the system `'$env:COMPUTERNAME`'...")
        [Microsoft.Dism.Commands.BasicDriverObject[]]$driversInstalled = Get-WindowsDriver -Online
    }
    catch {
        Write-Warning -Message $timeStamp.GetStamp("Cannot get drivers installed on the system `'$env:COMPUTERNAME`'! Exiting.")
        return $false
    }

    if (-not $driversInstalled) {
        Write-Warning -Message $timeStamp.GetStamp("Third-party drivers were not found on the system `'$env:COMPUTERNAME`'! Exiting.")
        return $false
    }

    Write-Verbose -Message $timeStamp.GetStamp("Found $($driversInstalled.Count) drivers total. Continue...")
    [Microsoft.Dism.Commands.BasicDriverObject[]]$driversMatch = $driversInstalled.Where({
        ($_.OriginalFileName -match '\\USBIPEnum.inf$') -and `
        ($_.CatalogFile -eq 'USBIPEnum.cat') -and `
        ([version]$_.Version -ge $Version)
    })

    if (-not $driversMatch) {
        Write-Warning -Message $timeStamp.GetStamp("USBIP drivers with version `'$Version`' were not found on the system `'$env:COMPUTERNAME`'! Exiting.")
        return $false
    }

    $driversMatch.ForEach({
        Write-Verbose -Message $timeStamp.GetStamp("Found driver `'$($_.Driver)`' with version `'$($_.Version)`' and original filename `'$($_.OriginalFileName)`'.")
    })

    Write-Verbose -Message $timeStamp.GetStamp("The USBIP drivers with version greater of equal to `'$Version`' found. Returning `'$true`'.")
    return $true
}