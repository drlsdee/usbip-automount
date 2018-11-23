#We assume that IP, MAC and name of USBIP host may be changed at any time.
#Also we need to catch event when shared device disappears by any cause
#and try to reconnect

#Set input parameters
param (
        $USBIP_hostname, #or CNAME
        $USBIP_portnumber, # For USBIP it is 3240 TCP by default.
        $VendorID, # It maybe "Aladdin" or "0529:"
        $USBIP_clientname # Name of USBIP client executable. It is usually named as "usbip.exe".
        )

IF ($USBIP_hostname -eq $null)
    {
    $USBIP_hostname = "centos-usbip"
    #If name(s) of target host(s) is (are) not given as argument, script will prompt you for input.
    #$USBIP_hostname = Read-Host "Enter hostname here"
    } #end IF

IF ($USBIP_portnumber -eq $null)
    {
    $USBIP_portnumber = 3240
    #If port number is not given as argument, script will prompt you for input.
    #$USBIP_portnumber = read-host "Enter port number here"
    } #end IF

IF ($VendorID -eq $null)
    {
    $VendorID = "Aladdin"
    #If name of vendor is not given as argument, script will prompt you for input.
    #$VendorID = Read-Host "Enter Vendor_ID here"
    } #end IF

IF ($USBIP_clientname -eq $null)
    {
    $USBIP_clientname = "usbip.exe"
    #If name of executable is not given as argument, script will prompt you for input.
    #$USBIP_clientname = Read-Host "Enter name of USBIP client executable here"
    } #end IF

$USBIP_inetaddr=[System.Net.Dns]::GetHostAddresses("$USBIP_hostname") | Select-Object IPAddressToString -expandproperty IPAddressToString

# Get path to current script. Yes, this script should be placed in same dir with USBIP client.
$ScriptPath = $MyInvocation.MyCommand.Definition | Split-Path

# Set CMD
$CMD = "$ScriptPath\$USBIP_clientname"

# Set location
Set-Location -Path $ScriptPath

# Set new source for Application EventLog
# New-EventLog –LogName Application –Source “USBIP client”


function Test-Port()
    {
    $Msg = "Trying to get IP from hostname"
    echo $Msg
    IF ("$USBIP_inetaddr" -ne "")
        {
        $Msg = "IP of $USBIP_hostname resolved as $USBIP_inetaddr"
        echo $Msg
        }
        ELSE
            {
            $Msg = "IP of $USBIP_hostname cannot be resolved"
            echo $Msg
            }

    $TcpClient = New-Object Net.Sockets.TcpClient
    # We use Try\Catch to remove exception info from console if we can't connect
    try
        {
        $TcpClient.Connect($USBIP_inetaddr,$USBIP_portnumber)
        } catch
                {
                $Msg = "Cannot connect to $USBIP_portnumber on $USBIP_hostname!"
                echo $Msg
                }

        IF($TcpClient.Connected)
            {
            $TcpClient.Close()
            $Msg = "Port $USBIP_portnumber is operational"
            echo $Msg
            } #endIF
        ELSE
            {
            $Msg = "Port $USBIP_portnumber on $USBIP_inetaddr is closed, "
            echo $Msg
            }
    }

function Device-List-and-Mount() {
    # List all exported devices and pipe stderr to variable
    Invoke-Expression "$CMD -l  $USBIP_hostname" -ErrorVariable ErrOutput

    # Select part of output which contains info about devices. Convert it from error to string.
    $DevicesRaw = $ErrOutput[1].ToString()

    # Split by Newline char | Select strings by pattern "xxxx:xxxx" where "x" may be letter or digit
    $DevArray = $DevicesRaw.Split("`n") -ne $null | Select-String -Pattern '[a-z0-9]{4}:[a-z0-9]{4}'
    # Define array with device IDs
    $BusIDs = @()

    [int]$DevNumber = $null
    While ($DevNumber -lt $DevArray.Count) {
        # Convert MatchInfo to string and select busID
        $BusIDs += $DevArray[$DevNumber].ToString().Substring(5,3)
        $DevNumber ++
        }

    foreach ($ID in $BusIDs) {
        echo $ID
        Start-Process $CMD -ArgumentList "-a $USBIP_hostname $ID" -NoNewWindow
        }
    }

function WatchDevices()
    {
        # Just get list of any USB devices
        $AllDevices = gwmi Win32_USBControllerDevice
        WHILE ($AllDevices) {
            echo "Present"
            # Write-EventLog -LogName "Application" -Source "USBIP client" -EventID 3001 -EntryType Information -Message "Devices are present."
            Sleep 60
            $AllDevices = gwmi Win32_USBControllerDevice
            } 
        echo "Not found"
    }

Test-Port
Device-List-and-Mount
WatchDevices
