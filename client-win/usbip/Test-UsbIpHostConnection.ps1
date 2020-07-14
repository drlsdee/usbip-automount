function Test-UsbIpHostConnection {
    [CmdletBinding()]
    param (
        # Hostname
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Name'
        )]
        [string]
        $ComputerName,

        # Host IP address
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'IP'
        )]
        [ipaddress]
        $IPAddress,

        # USBIP TCP port (default is 3240)
        [Parameter()]
        [ValidateRange(0,65535)]
        [int]
        $Port = 3240
    )
    [string]$myName = "$($MyInvocation.MyCommand.Name):"
    Write-Verbose -Message "$myName Starting function..."
    if ($ComputerName)
    {
        [string]$hostNoun = 'hostname'
        Write-Verbose -Message "$myName Resolving $hostNoun `"$ComputerName`"..."
        [string]$stringToResolve = $ComputerName
    }
    elseif ($IPAddress)
    {
        [string]$hostNoun = 'IP address'
        Write-Verbose -Message "$myName Resolving $hostNoun `"$IPAddress`"..."
        [string]$stringToResolve = $IPAddress
    }
    
    try
    {
        [System.Net.IPHostEntry]$resolveResult = [System.Net.Dns]::Resolve($stringToResolve)
    }
    catch [System.Net.Sockets.SocketException]
    {
        Write-Warning -Message "$myName The $hostNoun `"$stringToResolve`" probably does not exist! Exiting."
        return $false
    }
    catch
    {
        Write-Warning -Message "$myName Cannot resolve $hostNoun `"$stringToResolve`"! Exiting."
        return $false
    }
    
    [string[]]$addressStrings = $resolveResult.AddressList
    if ($resolveResult.HostName -in $addressStrings) {
        Write-Warning -Message "$myName The $hostNoun `"$stringToResolve`" probably either is not used by any of the known hosts or is not registered in the known DNS zones. Continue anyway."
    }
  
    if ($resolveResult.Aliases) {
        Write-Verbose -Message "$myName Set target hostname to alias: $($resolveResult.Aliases[0])"
        [string]$hostNameForTest = $resolveResult.Aliases[0]
    }
    else {
        Write-Verbose -Message "$myName Set target hostname to $($hostNoun): $($resolveResult.HostName)"
        [string]$hostNameForTest = $resolveResult.HostName
    }

    Write-Verbose -Message "$myName Starting connection test to the computer `"$hostNameForTest`", TCP port $Port..."
    $testResult = Test-NetConnection -ComputerName $hostNameForTest -Port $Port -InformationLevel Detailed

    if      ($testResult.TcpTestSucceeded)
    {
        Write-Verbose -Message "$myName The computer `"$hostNameForTest`" is up and the port $Port is operational."
        return $true
    }
    elseif  ($testResult.PingSucceeded)
    {
        Write-Warning -Message "$myName The computer `"$hostNameForTest`" is up but the port $Port is CLOSED. Maybe the computer still boots up. Also check your firewal rules."
        return $false
    }
    else
    {
        Write-Warning -Message "$myName The computer `"$hostNameForTest`" is DOWN OR UNREACHABLE!"
        return $false
    }
}
