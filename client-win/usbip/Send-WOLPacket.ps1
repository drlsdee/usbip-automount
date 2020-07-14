function Send-WOLPacket {
    [CmdletBinding()]
    param (
        # MAC address of the host
        [Parameter(Mandatory)]
        [string]
        $MACaddress,

        # UDP port for WOL - maybe 0, 7 or 9, default is 7
        [Parameter()]
        [ValidateSet(0, 7, 9)]
        [int]
        $Port = 7
    )
    [string]$myName = "$($MyInvocation.MyCommand.Name):"
    Write-Verbose -Message "$myName Starting function..."
    $MACaddressFixed = [regex]::Replace(($MACaddress.ToUpperInvariant()), '[^0-9A-Z]', '')
    if (-not $MACaddressFixed) {
        Write-Warning -Message "$myName Given string `"$($MACaddress)`" was incorrect. Exiting."
        return $false
    }

    try {
        Write-Verbose -Message "$myName Converting given string `"$($MACaddress)`" into object of type '[System.Net.NetworkInformation.PhysicalAddress]'..."
        [PhysicalAddress]$addressPhysical = [PhysicalAddress]::Parse($MACaddressFixed)
    }
    catch [FormatException] {
        Write-Warning -Message "$myName The MAC address `"$($MACaddress)`" is incorrect! Exiting."
        return $false
    }
    catch {
        Write-Warning -Message "$myName Something wrong..."
        return $_
    }

    Write-Verbose -Message "$myName Converting address `"$($MACaddress)`" to the byte array..."
    [byte[]]$bytesAddress = $addressPhysical.GetAddressBytes() * 16

    Write-Verbose -Message "$myName Creating a prefix with 6 bytes 0xFF..."
    [byte[]]$bytesPrefix = [byte[]]@(, 0xFF * 6)
    
    Write-Verbose -Message "$myName ...and putting it together."
    [byte[]]$bytesWOL = @($bytesPrefix + $bytesAddress)

    [System.Net.IPAddress]$ipBroadCast = [System.Net.IPAddress]::Broadcast
    [System.Net.IPEndpoint]$ipEndpoint = [System.Net.IPEndpoint]::new($ipBroadCast, $Port)

    [System.Net.Sockets.UdpClient]$udpClient = [System.Net.Sockets.UdpClient]::new()
    Write-Verbose -Message "$myName Sending datagram of $($bytesWOL.Count) bytes to the broadcast address $($ipEndpoint.Address), port $($ipEndpoint.Port)..."
    [int]$sendResult = $udpClient.Send($bytesWOL, $bytesWOL.Count, $ipEndpoint)
    if ($sendResult -ne $bytesWOL.Count) {
        Write-Warning -Message "$myName Something wrong! The count of bytes sent $($sendResult) is NOT equal to the expected count of $($bytesWOL.Count)!"
        return $false
    }
    Write-Verbose -Message "$myName The $($sendResult)-byte WOL datagram was successfully sent to the broadcast address $($ipEndpoint.Address), port $($ipEndpoint.Port). End of the function."
    return $true
}
