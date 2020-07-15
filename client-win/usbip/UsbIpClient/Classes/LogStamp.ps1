<#
A small PowerShell class designed to write timestamps and function names in log and output messages.
The default format for timestamps is a string in RFC 3389 / ISO 8601 format.
By default, the timestamp is set in accordance with the local time of the system, indicating the offset value relative to UTC.
You can override this, e.g., by explicitly specifying UTC time use or a custom date and time format.
Usage
0. Import the class.
1. Create a new object inside your function, e.g. with default constructor:
$timeStamp = [LogStamp]::new([System.String]$MyInvocation.InvocationName)
2. Use the appropriate methods of the class.
The command
Write-Verbose -Message "$($timeStamp.GetStamp()) Starting the function..."
will return:
PS:> VERBOSE: 2020-06-29T18:35:13.3094603+05:00: Test-LogStampClass: Starting the function...
or
Write-Warning -Message $timeStamp.GetStamp('SOMETHING WRONG!')
will return the output:
WARNING: 2020-06-29T18:35:13.3444616+05:00: Test-LogStampClass: SOMETHING WRONG!
Or use the 'GetStampObject()' / 'GetStampObject([string] Message)' methods to get the log message as a hashtable with keys 'TimeStamp', 'InvocationName' and, optionally, 'Message' for further processing.
$PSVersionTable:
    PSVersion                      5.1.14393.3471
    PSEdition                      Desktop
    PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0, 5.0, 5.1}
    BuildVersion                   10.0.14393.3471
    CLRVersion                     4.0.30319.42000
    WSManStackVersion              3.0
    PSRemotingProtocolVersion      2.3
    SerializationVersion           1.1.0.1
#>



class LogStamp {
    # Property: the invocation name
    [string]
    $InvocationName

    # Property: the format string for timestamps
    [string]
    $Format = 'yyyy-MM-ddTHH:mm:ss.fffffffK'

    # Property: return UTC time or local time
    [bool]
    $Utc

    # Constructor: Creates a new LogStamp object, with the specified InvocationName
    LogStamp(
        [string]
        $newInvocationName
    )
    {
        # Set invocation name for LogStamp
        $this.InvocationName = $newInvocationName
    }

    # Constructor: Creates a new LogStamp object, with the specified InvocationName and format string
    LogStamp(
        [String]
        $newInvocationName,

        [string]
        $newFormat
    )
    {
        # Set invocation name for LogStamp
        $this.InvocationName = $NewInvocationName
        # Set format string for LogStamp
        $this.Format = $newFormat
    }

    # Constructor: Creates a new LogStamp object, with the specified InvocationName, format string and UTC property
    LogStamp(
        [String]
        $newInvocationName,

        [string]
        $newFormat,

        [bool]
        $newUtc
    )
    {
        # Set invocation name for LogStamp
        $this.InvocationName = $NewInvocationName
        # Set format string for LogStamp
        $this.Format = $newFormat
        # Set UTC property for LogStamp
        $this.Utc = $newUtc
    }

    # Constructor: Creates a new LogStamp object, with the specified InvocationName, UTC property and default format string
    LogStamp(
        [String]
        $newInvocationName,

        [bool]
        $newUtc
    )
    {
        # Set invocation name for LogStamp
        $this.InvocationName = $NewInvocationName
        # Set UTC property for LogStamp
        $this.Utc = $newUtc
    }

    # Method: Returns a string with the current timestamp and the specified InvocationName, separated with colon: ':'
    [string]
    GetStamp()
    {
        if ($this.Utc) {
            [string]$stampString = "$([datetime]::UtcNow.ToString($this.Format)): $($this.InvocationName):"
        }
        else {
            [string]$stampString = "$([datetime]::Now.ToString($this.Format)): $($this.InvocationName):"
        }
        return $stampString
    }

    # Method: Returns a string with the current timestamp, the specified InvocationName and with the message string, separated with colon: ':'
    [string]
    GetStamp(
        [string]
        $Message
    )
    {
        if ($this.Utc) {
            [string]$stampString = "$([datetime]::UtcNow.ToString($this.Format)): $($this.InvocationName): $Message"
        }
        else {
            [string]$stampString = "$([datetime]::Now.ToString($this.Format)): $($this.InvocationName): $Message"
        }
        return $stampString
    }

    # Method: Returns a hashtable with the specified InvocationName and current TimeStamp; keys are called exactly the same.
    [hashtable]
    GetStampObject()
    {
        if ($this.Utc) {
            [string]$stampString = "$([datetime]::UtcNow.ToString($this.Format))"
        }
        else {
            [string]$stampString = "$([datetime]::Now.ToString($this.Format))"
        }
        [hashtable]$stampTable = @{
            TimeStamp = $stampString
            InvocationName = $this.InvocationName
        }
        return $stampTable
    }

    # Method: Returns a hashtable with the specified InvocationName and current TimeStamp; keys are called exactly the same.
    [hashtable]
    GetStampObject(
        [string]
        $Message
    )
    {
        if ($this.Utc) {
            [string]$stampString = "$([datetime]::UtcNow.ToString($this.Format))"
        }
        else {
            [string]$stampString = "$([datetime]::Now.ToString($this.Format))"
        }
        [hashtable]$stampTable = @{
            TimeStamp = $stampString
            InvocationName = $this.InvocationName
            Message = $Message
        }
        return $stampTable
    }
}