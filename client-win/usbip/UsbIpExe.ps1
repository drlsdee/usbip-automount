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

    [void]
    FillProperties(
        [string[]]$devicePropertyStrings
    )
    {
        [string[]]$deviceInfoGeneral    = $devicePropertyStrings[0].Split(':()').Where({$_}).TrimStart(' ').TrimEnd(' ')
        $this.BusID = $deviceInfoGeneral[0]
        $this.VendorName = $deviceInfoGeneral[1]
        $this.DeviceName = $deviceInfoGeneral[2]
        $this.VendorID = $deviceInfoGeneral[3]
        $this.ProductID = $deviceInfoGeneral[4]

        [string]$deviceRemoteAddress    = $devicePropertyStrings[1].TrimStart(': ')
        $this.RemoteAddress = $deviceRemoteAddress
        #[string]$deviceClassString0     = $devicePropertyStrings[2].TrimStart(': ')
        #[string]$deviceClassString1     = $devicePropertyStrings[3].TrimStart(': ')
    }

    UsbRemoteInfo(
        [string[]]$deviceInfoRaw
    )
    {
        $this.FillProperties($deviceInfoRaw)
    }
}

class UsbIpExe {
    static
    # Path to the folder where the 'usbip.exe' is placed
    [System.String]
    $workFolder

    static
    # Name of the USBIP executable file, default is 'usbip.exe'
    [System.String]
    $exeName = 'usbip.exe'

    static
    # Debug messages pattern
    [System.Text.RegularExpressions.Regex]
    $patternDebug = '^(usbip){1}\s+(dbg:){1}\s+'

    static
    hidden
    # Error messages pattern
    [System.Text.RegularExpressions.Regex]
    $patternError = '^(usbip){1}\s+(err:){1}\s+'
    
    # Help message
    [System.String[]]
    $Help

    # Version as string
    [System.String]
    $VersionString

    # Version as version
    [System.Version]
    $Version

    # General output of the executable, excepting help message and version.
    [System.String[]]
    $Output

    # Debug messages
    [System.String[]]
    $DebugMessages

    # Error messages
    [System.String[]]
    $ErrorMessages

    # Devices list
    [System.Collections.Hashtable]
    $Devices

    static
    # A method that gets the fullname from default path
    [System.String]GetFullNameFromEnvPath(
        [System.String]$fileName
    )
    {
        [System.String[]]$pathsSplitted = $env:Path.Split(';').Where({
            (-not [System.String]::IsNullOrEmpty($_)) -and `
            (-not [System.String]::IsNullOrWhiteSpace($_))
        })

        [System.String[]]$pathsToCheck = $pathsSplitted.ForEach({
            [System.IO.Path]::Combine($_, $fileName)
        })

        [System.String[]]$pathChecked = $pathsToCheck.Where({
            [System.IO.File]::Exists($_)
        })

        [System.String]$folderToReturn = [System.IO.Path]::GetDirectoryName($pathChecked[0])

        return $folderToReturn
    }

    static
    # A method that creates the process object
    [System.Diagnostics.Process]
    CreateProcess(
        [System.String]$folderPath,
        [System.String]$fileName
    )
    {
        [System.String]$fullName                        = [System.IO.Path]::Combine($folderPath, $fileName)
        [System.Diagnostics.ProcessStartInfo]$startInfo = [System.Diagnostics.ProcessStartInfo]::new($fullName)
        $startInfo.WorkingDirectory                     = $folderPath
        $startInfo.UseShellExecute                      = $false
        $startInfo.CreateNoWindow                       = $true
        $startInfo.RedirectStandardError                = $true
        $startInfo.RedirectStandardOutput               = $true

        [System.Diagnostics.Process]$processObject      = [System.Diagnostics.Process]::new()
        $processObject.StartInfo                        = $startInfo

        return $processObject
    }

    static
    # A method that reads the output stream
    [System.String[]]
    ReadOutputStream(
        [System.IO.StreamReader]$Stream
    )
    {
        [System.Int32]$codePageSrc          = $Stream.CurrentEncoding.CodePage
        [System.Int32]$codePageOut          = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.OEMCodePage
        [System.Text.Encoding]$encToRead    = [System.Text.Encoding]::GetEncoding($codePageSrc)
        [System.Text.Encoding]$encToWrite   = [System.Text.Encoding]::GetEncoding($codePageOut)

        [System.String[]]$stringsOut        = @()

        while (
            -not ($Stream.EndOfStream)
        )
        {
            [System.String]$strRaw      = $Stream.ReadLine()
            [System.Byte[]]$bytesRaw    = $encToRead.GetBytes($strRaw)
            [System.String]$strConv     = $encToWrite.GetString($bytesRaw)
            if (
                (-not [System.String]::IsNullOrEmpty($strConv)) -and `
                (-not [System.String]::IsNullOrWhiteSpace($strConv))
            )
            {
                $stringsOut += $strConv
            }
        }

        return $stringsOut
    }

    # A method that parses the output strings
    static
    [System.String[]]
    ParseOutput(
        [System.String[]]$inputStrings,
        [System.Text.RegularExpressions.Regex]$pattern
    )
    {
        [System.String[]]$stringsFiltered = $inputStrings.Where({
            $pattern.IsMatch($_)
        })

        [System.String[]]$stringsTrimmed = $stringsFiltered.ForEach({
            $pattern.Replace($_, '')
        })
        return $stringsTrimmed
    }

    # A method that starts the USBIP executable
    [System.String[]]
    StartProcess(
        [System.String]$Arguments
    )
    {
        [System.Diagnostics.Process]$processObject = $this::CreateProcess($this::workFolder, $this::exeName)
        $processObject.StartInfo.Arguments = $Arguments
        $processObject.Start()
        [System.String[]]$outputMain = $this::ReadOutputStream($processObject.StandardError)
        [System.String[]]$outputVersionAndHelp = $this::ReadOutputStream($processObject.StandardOutput)

        if      ($Arguments -eq '-h')
        {
            $this.Help = $outputVersionAndHelp
            return $outputVersionAndHelp
        }
        elseif  ($Arguments -eq '-v')
        {
            $this.VersionString = $outputVersionAndHelp[0]
            $this.Version = $outputVersionAndHelp[0] -replace '[^0-9.]'
            return $outputVersionAndHelp
        }
        else
        {
            return $outputMain
        }
    }

    # Method: just get help
    [System.String[]]
    GetHelp()
    {
        return $this.StartProcess('-h')
    }

    [System.String]
    GetVersion()
    {
        return $this.StartProcess('-v')
    }

    # Method: list devices on the remote host
    [System.Management.Automation.PSObject]
    List(
        [System.String]$remoteHostName
    )
    {
        [System.Text.RegularExpressions.Regex]$hostNamePattern = "- $($remoteHostName)$"
        [System.String]$argumentString  = "-l $remoteHostName -D"
        [System.String[]]$devicesInfoRaw   = $this.StartProcess($argumentString).Where({
            -not $hostNamePattern.IsMatch($_)
        })

        [System.Management.Automation.PSObject]$devicesList = [System.Management.Automation.PSObject]::new(@{
            hostName = $remoteHostName
            outputRaw = $devicesInfoRaw
            errorMsg = [System.String[]]@()
            devices = [UsbRemoteInfo[]]@()
        })

        [System.String[]]$devicesErrorMessages = $devicesInfoRaw.Where({
            [regex]::IsMatch($_, $this::patternError)
        })

        [System.String[]]$devicesDebugMessages = $devicesInfoRaw.Where({
            [regex]::IsMatch($_, $this::patternError) -or `
            [regex]::IsMatch($_, $this::patternDebug)
        })

        [System.String[]]$devicesInfoMessages = $devicesInfoRaw.Where({
            (-not [regex]::IsMatch($_, $this::patternError)) -and `
            (-not [regex]::IsMatch($_, $this::patternDebug))
        })

        if ($devicesErrorMessages) {
            $devicesList.errorMsg = $devicesDebugMessages
        }
        else {
            $indexStart = 0
            $indexEnd = $indexStart + 3

            do {
                [string[]]$deviceCurrent = $devicesInfoMessages[($indexStart)..($indexEnd)]
                $devicesList.devices += [UsbRemoteInfo]::new($deviceCurrent)
                $indexStart = $indexStart + 4
                $indexEnd = $indexStart + 3
            } while ($indexEnd -lt $devicesInfoMessages.Count)
        }
        
        return $devicesList
    }

    UsbIpExe()
    {
        $this::workFolder = $this::GetFullNameFromEnvPath($this::exeName)
    }

    UsbIpExe(
        [System.String]$workFolder
    )
    {
        $this::workFolder = $workFolder
    }

    UsbIpExe(
        [System.String]$workFolder,
        [System.String]$exeName
    )
    {
        $this::workFolder = $workFolder
        $this::exeName = $exeName
    }
}

function TestMe {
    [CmdletBinding()]
    param ()
    [string]$myName = "$($MyInvocation.MyCommand.Name):"
    Write-Verbose "$myName Create an object"
    $usbIPObj = [UsbIpExe]::new('C:\usbip')

    Write-Verbose "$myName Start process and get help"
    #$usbIPObj.GetHelp()
    Write-Verbose "$myName Reading help from properties"
    #$usbIPObj.Help

    Write-Verbose "$myName Get version string"
    #$usbIPObj.GetVersion()
    Write-Verbose "$myName Reading version from properties"
    #$usbIPObj.VersionString
    #$usbIPObj.Version
    
    [string[]]$hostList = @(
        'usboip'
    #    'demo-srv00'
        'centos7gen2'
    )

    Write-Verbose "$myName Trying to get info about hosts: $hostList"
    $hostCurr = $hostList[0]
    #$usbResult = $usbIPObj.List($hostCurr)
    $usbResult = $hostList.ForEach({
        $usbIPObj.List($_)
    })
    $usbResult
}

$tmpResult = TestMe -Verbose
$tmpResult[0]#.Where({$_.errorMsg})