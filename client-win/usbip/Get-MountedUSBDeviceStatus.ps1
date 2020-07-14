function Get-MountedUSBDeviceStatus {
    [CmdletBinding()]
    param (
        [Parameter()]
        # Vendor ID
        [string]
        $VendorID,

        [Parameter()]
        # Product ID
        [string]
        $ProductID
    )
    [string]$myName = "$($MyInvocation.InvocationName):"
    Write-Verbose -Message "$myName Starting function..."
    
    [regex]$deviceIdString = [regex]::Escape("USB\VID_$($VendorID)&PID_$($ProductID)")
    Write-Verbose -Message "$myName DeviceID string: $($deviceIdString)"
    
    # Getting the device list
    [System.Management.ManagementObject[]]$devicesAll = Get-WmiObject -Class Win32_USBDevice
    if (-not $devicesAll)
    {
        Write-Warning -Message "$myName No USB devices were found! Returning `"$($false)`"."
        return $false
    }

    Write-Verbose -Message "$myName Found $($devicesAll.Count) USB devices total. Filtering by VID&PID: $($deviceIdString)"

    [System.Management.ManagementObject[]]$devicesMatch = $devicesAll.Where({
        $deviceIdString.IsMatch($_.DeviceId)
    })
    if (-not $devicesMatch)
    {
        Write-Warning -Message "$myName No USB devices with VID&PID matching to the string `"$($deviceIdString)`" were found! Returning `"$($false)`"."
        return $false
    }

    Write-Verbose -Message "$myName Found $($devicesAll.Count) USB devices with VID&PID matching to the string `"$($deviceIdString)`". Returning `"$($true)`"."
    $devicesMatch.ForEach({
        Write-Verbose -Message "$myName Device: $($_.Name); manufacturer: $($_.Manufacturer); Device ID: $($_.DeviceID)"
    })
    return $true
}
