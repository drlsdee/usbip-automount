class UsbRemoteInfo {
    # Device Bus ID
    [string]
    $BusID

    # Device vendor name
    [string]
    $VendorName

    # Device vendor ID (PID)
    [string]
    $VendorID

    # Device name
    [string]
    $DeviceName

    # Device ID (PID)
    [string]
    $ProductID

    # Device remote address
    [string]
    $RemoteAddress

    [void]GetAdditionalStrings(
        [string[]]$stringAdditional
    )
    {
        $this.RemoteAddress = $stringAdditional[0]
    }

    [void]
    SplitGeneralInfo(
        [string]$sourceString
    )
    {
        [string[]]$stringsSplitted = $sourceString.Split(':()').Where({$_}).TrimStart(' ').TrimEnd(' ')
        $this.BusID = $stringsSplitted[0]
        $this.VendorName = $stringsSplitted[1]
        $this.DeviceName = $stringsSplitted[2]
        $this.VendorID = $stringsSplitted[3]
        $this.ProductID = $stringsSplitted[4]
    }

    [void]FillProperties(
        
    )
    {}

    UsbRemoteInfo(
        [string]$devicesInfoGeneral
    )
    {
        $this.SplitGeneralInfo($devicesInfoGeneral)
    }
}

function ParseDeviceList {
    param (
        [string[]]
        $listInput,
        [string]
        $hostName = 'usboip'
    )
    [regex]$hostNamePattern = "- $($hostName)$"
    
    [string[]]$devicesInfoRaw = $listInput.Where({
        -not $hostNamePattern.IsMatch($_)
    }).TrimStart(' ')

    $indexStart = 0
    $indexEnd = $indexStart + 3

    do {
        [string[]]$deviceCurrent = $devicesInfoRaw[($indexStart)..($indexEnd)]
        "=== Current device ==="
        $deviceCurrent
        "--- End ---"
        $indexStart = $indexStart + 4
        $indexEnd = $indexStart + 3
    } while ($indexEnd -lt $devicesInfoRaw.Count)

    [string[]]$devicesInfoGeneral = $devicesInfoRaw.Where({
        [regex]::IsMatch($_, '^\d+')
    })
    #$devicesInfoGeneral
    $outputObjects = @()

    $devicesInfoGeneral.ForEach({
        <# [string]$strCurr = $_
        [int]$indCurr = $devicesInfoRaw.IndexOf($strCurr)
        [string]$remoteAddress = $devicesInfoRaw[($indCurr + 1)].TrimStart(': ')
        "Remote address: $remoteAddress" #>
        $outputObjects += [UsbRemoteInfo]::new($_)
    })
    return $outputObjects
}

[string[]]$devDummy = @(
    '- usboip'
    '     1-8: Aladdin Knowledge Systems : HASP v0.06 (0529:0001)'
    '        : /sys/devices/pci0000:00/0000:00:01.2/0000:01:00.0/usb1/1-8'
    '        : Vendor Specific Class / unknown subclass / unknown protocol (ff/00/00)'
    '        :  0 - Vendor Specific Class / unknown subclass / unknown protocol (ff/00/00)'
    '     1-2.2: Dummy Vendor : Device name (0529:0001)'
    '        : /sys/devices/pci0000:00/0000:00:01.2/0000:01:00.0/usb1/1-2'
    '        : Vendor Specific Class / unknown subclass / unknown protocol (ff/00/01)'
    '        :  1 - Vendor Specific Class / unknown subclass / unknown protocol (ff/00/01)'
)

ParseDeviceList -listInput $devDummy