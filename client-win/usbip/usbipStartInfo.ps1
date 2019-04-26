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

function JoinStringsNotNull ([array]$array) {
    $string = ($array.Where({$_.Length -gt 0})) -join ' '
    return $string
}

$hostString = JoinStringsNotNull $hostlist

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

#$testAppInfo.Arguments = '-l $hostlist'
$testAppOut = StartTestApp
$testAppOut