$workingDir = "C:\usbip"
$fileName = "usbip.exe"
$hostList = @(
    "192.168.0.8",
    "192.168.0.9",
    "",
    "admin-00"
)

$optionArray = @(
    "--attach", # [host] [bus_id] Attach a remote USB device.
    "--detach", # [ports] Detach an imported USB device.
    "--list", # [hosts] List exported USB devices.
    "--port", # List virtual USB port status.
    "--debug", # Print debugging information.
    "--version", # Show version.
    "--help" # Print this help.
)

function ConcatArguments {
    [CmdletBinding()]
    param (
        # Enables internal debugging.
        [Parameter()]
        [bool]
        $internalDBG,

        # List of possible actions.
        [Parameter(Mandatory)]
        [ValidateSet("List","Mount","Unmount","Port")]
        [string]$Action,

        # Hostname or IP address of host.
        [Parameter(DontShow)]
        [string]
        $singleHost,

        # Bus ID of remote device.
        [Parameter(DontShow)]
        [string]
        $busID,

        # Ports to detach
        [Parameter(DontShow)]
        [array]
        $Ports
    )

    function ArrayToString {
        param (
            # Array of strings to join
            [array]
            $Array
        )
        $String = ($array.Where({($_.Length -gt 0)})) -join ' '
        return $String    
    }

    switch ($Action) {
        "List" {
            $command = $optionArray[2]
            $target = ArrayToString $hostList
        }
        "Mount" {
            $command = $optionArray[0]
            $target = ArrayToString @($singleHost,$busID)
        }
        "Unmount" {
            $command = $optionArray[1]
            if ($Ports) {
                $target = ArrayToString $Ports
            } else {
                $target = "*"
            }
        }
        "Port" {
            $command = $optionArray[3]
        }
        Default {
            "List"
        }
    }

    if ($internalDBG) {
        $argPart2 = $optionArray[4]
    }

    $outArgs = ArrayToString @($command, $target, $argPart2)
    return $outArgs
    Write-Host $msg
}

$procName = $workingDir | Join-Path -ChildPath $fileName

$testAppInfo = New-Object System.Diagnostics.ProcessStartInfo
$testAppInfo.WorkingDirectory = $workingDir
$testAppInfo.FileName = $procName
$testAppInfo.UseShellExecute = $false
$testAppInfo.RedirectStandardOutput = $true
$testAppInfo.RedirectStandardError = $true

$testApp = New-Object System.Diagnostics.Process
$testApp.StartInfo = $testAppInfo

function ReadOutput ([System.IO.StreamReader]$in) {
    $outBuffer = @()
    while ($in.Peek() -gt 0) {
        $line = ($in.ReadLine()) -replace '\t+'
        if ($line.Length -gt 0) {
            $outBuffer += $line
        }
    }
    $outBuffer
}

function StartTestApp () {
    $testApp.Start()
    $testOuts = @{}
    $testOuts.Out = ReadOutput $testApp.StandardOutput
    $testOuts.Err = ReadOutput $testApp.StandardError
    return $testOuts
}

$testAppInfo.Arguments = ConcatArguments -internalDBG 0 -Action List
$testAppOut = StartTestApp
$testAppOut