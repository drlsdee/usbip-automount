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

    # Method: The method reads the raw output and returns either raw output
    # (if error messages have appeared) or comment on successful action.
    static
    [System.String[]]
    FilterErrors(
        [System.String[]]$outputRaw,
        [System.String]$commentSuccess,
        [System.String]$commentError
    )
    {
        [System.String[]]$outputErr = $outputRaw.Where({
            $this::patternError.IsMatch($_)
        })

        if ($outputErr.Count -gt 0)
        {
            [System.String[]]$stringsToOut = @(
                $commentError,
                'See raw output below:'
                $outputRaw
            )
        }
        else
        {
            [System.String[]]$stringsToOut = @(
                $commentSuccess
            )
        }
        return $stringsToOut
    }

    # Method: The method splits the raw output
    # of the USBIP command 'usbip <-l | --list> [hostname] into 4-line blocks
    # and then creates an object of type [UsbRemoteInfo] from each of the blocks.
    static
    [System.Management.Automation.PSObject]
    GetDeviceInfo(
        [System.String[]]$outputClean
    )
    {
        [System.Int32]$indexStart = 0
        [System.Int32]$indexEnd = 3
        [System.Int32]$blockSize = 4
        [UsbRemoteInfo[]]$devicesList = @()
        while ($indexEnd -lt $outputClean.Count) {
            [System.String[]]$blockToParse = $outputClean[($indexStart)..($indexEnd)]
            $devicesList += [UsbRemoteInfo]::new($blockToParse)
            $indexStart = $indexStart + $blockSize
            $indexEnd = $indexEnd + $blockSize
        }
        return $devicesList
    }

    # Method: the method starts the USBIP executable with an argument string.
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
        [System.Text.RegularExpressions.Regex]$hostNamePattern = "^- $($remoteHostName)$"
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
            $this::patternError.IsMatch($_)
        })

        [System.String[]]$devicesInfoMessages = $devicesInfoRaw.Where({
            (-not $this::patternError.IsMatch($_)) -and `
            (-not $this::patternDebug.IsMatch($_))
        })

        if ($devicesErrorMessages) {
            $devicesList.errorMsg = $devicesErrorMessages
        }
        else {
            $devicesList.devices = [UsbIpExe]::GetDeviceInfo($devicesInfoMessages)
        }
        
        return $devicesList
    }

    [System.String[]]
    Mount(
        [System.String]$remoteHostName,
        [System.String]$BusID
    )
    {
        [System.String]$Arguments = "-a $remoteHostName $BusID -D"
        [System.String[]]$actionResultRaw = $this.StartProcess($Arguments)
        [System.String]$messageSuccess = "Mounted device with bus ID $($BusID) from the host $($remoteHostName)"
        [System.String]$messageError = "Failed to mount device with bus ID $($BusID) from the host $($remoteHostName)!"
        return [UsbIpExe]::FilterErrors($actionResultRaw, $messageSuccess, $messageError)
    }

    [System.String[]]
    UnmountAll()
    {
        [System.String]$Arguments = '-d * -D'
        [System.String[]]$actionResultRaw = $this.StartProcess($Arguments)
        [System.String]$messageSuccess = "Devices unmounted successfully!"
        [System.String]$messageError = "Failed to unmount devices!"
        return [UsbIpExe]::FilterErrors($actionResultRaw, $messageSuccess, $messageError)
    }

    [System.String[]]
    UnmountPort(
        [System.Int32]$Port
    )
    {
        [System.String]$Arguments = "-d $Port -D"
        [System.String[]]$actionResultRaw = $this.StartProcess($Arguments)
        [System.String]$messageSuccess = "Device from the port $Port was unmounted successfully!"
        [System.String]$messageError = "Failed to unmount device from port $Port!"
        return [UsbIpExe]::FilterErrors($actionResultRaw, $messageSuccess, $messageError)
    }
    [System.String[]]
    ListPorts()
    {
        [System.Text.RegularExpressions.Regex]$patternPort = '^port (\d+)\: used$'
        [System.String]$Arguments = "-p"
        [System.String[]]$actionResultRaw = $this.StartProcess($Arguments)
        [System.String]$messageSuccess = "Devices list:"
        [System.String]$messageError = "Failed to get devices list!"
        [System.String[]]$errorList = $actionResultRaw.Where({
            $this::patternError.IsMatch($_)
        })
        [System.String[]]$portList = $actionResultRaw.Where({
            $patternPort.IsMatch($_)
        })
        if ($errorList)
        {
            return $errorList
        }
        if ($portList)
        {
            return $patternPort.Replace($portList, '$1')
        }
        return @($actionResultRaw)
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
    $usbIPObj.GetHelp()
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
    $usbResult = $usbIPObj.List($hostCurr)
    #$usbResult = $hostList.ForEach({$usbIPObj.List($_)})
    $usbResult.devices

    #$usbIPObj.Mount($hostList[0], $usbResult.devices.BusID)
    Write-Verbose "$myName Getting port list"
    $usbIPObj.ListPorts()
}

$tmpResult = TestMe -Verbose
$tmpResult