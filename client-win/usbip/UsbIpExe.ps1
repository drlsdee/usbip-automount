class UsbIpExe {
    static
    # Path to the folder where the 'usbip.exe' is placed
    [System.String]
    $workFolder

    static
    # Name of the USBIP executable file, default is 'usbip.exe'
    [System.String]
    $exeName = 'usbip.exe'

    # Standard output as array of strings
    [System.String[]]
    $Help

    # Standard error as array of strings
    [System.String[]]
    $Output

    # Debug messages
    [System.String[]]
    $DebugMessages

    # Devices list
    [System.Collections.Hashtable]
    $Devices

    # Debug messages pattern
    [System.Text.RegularExpressions.Regex]
    $patternDebug = '^(usbip){1}\s+(dbg:){1}\s+'

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
    [System.Diagnostics.Process]CreateProcess(
        [System.String]$folderPath,
        [System.String]$fileName
    )
    {
        [System.String]$fullName = [System.IO.Path]::Combine($folderPath, $fileName)
        [System.Diagnostics.ProcessStartInfo]$startInfo = [System.Diagnostics.ProcessStartInfo]::new($fullName)
        $startInfo.UseShellExecute        = $false
        $startInfo.CreateNoWindow         = $true
        $startInfo.RedirectStandardError  = $true
        $startInfo.RedirectStandardOutput = $true

        [System.Diagnostics.Process]$processObject = [System.Diagnostics.Process]::new()
        $processObject.StartInfo = $startInfo

        return $processObject
    }

    static
    # A method that reads the output stream
    [System.String[]]ReadOutputStream(
        [System.IO.StreamReader]$Stream
    )
    {
        [System.Int32]$codePageSrc = $Stream.CurrentEncoding.CodePage
        [System.Int32]$codePageOut = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.OEMCodePage
        [System.Text.Encoding]$encToRead = [System.Text.Encoding]::GetEncoding($codePageSrc)
        [System.Text.Encoding]$encToWrite = [System.Text.Encoding]::GetEncoding($codePageOut)

        [System.String[]]$stringsOut = @()

        while (
            -not ($Stream.EndOfStream)
        )
        {
            [System.String]$strRaw = $Stream.ReadLine()
            [System.Byte[]]$bytesRaw = $encToRead.GetBytes($strRaw)
            [System.String]$strConv = $encToWrite.GetString($bytesRaw)
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

    # A method that starts the USBIP executable and fills the 'Output' and 'Help' properties
    [void]
    StartProcess(
        [System.String]$Arguments
    )
    {
        #[System.String]$fullName = $this::GetFullName($this::BaseName)
        
        [System.Diagnostics.Process]$processObject = $this::CreateProcess($this::workFolder, $this::exeName)
        $processObject.StartInfo.WorkingDirectory = $this::workFolder
        $processObject.StartInfo.Arguments = $Arguments
        $processObject.Start()
        [System.String[]]$OutputRaw = $this::ReadOutputStream($processObject.StandardError)
        [System.String[]]$HelpRaw = $this::ReadOutputStream($processObject.StandardOutput)
        $this.Output = $OutputRaw
        $this.Help = $HelpRaw
        $this.DebugMessages = $this::ParseOutput($OutputRaw, $this.patternDebug)
    }

    # Method: just get help
    [void]
    GetHelp()
    {
        $this.StartProcess('-h')
    }

    # Method: list devices on the remote host(s)
    [void]
    List(
        [System.String[]]$hostsList
    )
    {
        [System.String]$hostString = [System.String]::Join(' ', $hostsList)
        [System.String]$argumentString = "-l $hostString -D"
        $this.StartProcess($argumentString)
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

function Get-UsbIds {
    [CmdletBinding()]
    param(
        [uri]
        $locationDefault = 'http://www.linux-usb.org/usb.ids',

        [string]
        $locationOnfileSystem
    )
    [string]$myName = "$($MyInvocation.MyCommand.Name):"
    Write-Verbose "$myName Get current location"
    [string]$locationCurrent = [System.IO.Directory]::GetCurrentDirectory()
    Write-Verbose "Current location is: $locationCurrent"

    Write-Verbose "$myName Search file usb.ids"
    [string]$filePath = "$($locationCurrent)\usb.ids"
    if (
        [System.IO.File]::Exists($filePath)
    )
    {
        Write-Verbose "$myName Exists: $filePath"
        return
    }

    Write-Verbose "$myName Trying to download file"
    $webClient = [System.Net.WebClient]::new()
    try {
        $webClient.DownloadFile($locationDefault, $filePath)
        Write-Verbose -Message "$myName The file was downloaded from $locationDefault to $filePath"
        return
    }
    catch {
        Write-Warning $_.Exception.Message
        return
    }
}

function TestMe {
    [CmdletBinding()]
    param ()
    [string]$myName = "$($MyInvocation.MyCommand.Name):"
    Write-Verbose "$myName Create an object"
    $usbIPObj = [UsbIpExe]::new('C:\usbip')

    Write-Verbose "$myName Start process"
    #$usbIPObj.StartProcess('-l usboip')

    Write-Verbose "$myName Get help"
    $usbIPObj.GetHelp()
    $usbIPObj.Help

    Write-Verbose "$myName List devices"
    [string[]]$hostList = @(
        'usboip'
        'demo-srv00'
        'centos7gen2'
    )
    $usbIPObj.List($hostList)

    Write-Verbose "$myName StdErr"
    $usbIPObj.Output
    
    Write-Verbose "$myName Debug"
    $usbIPObj.DebugMessages
}

#Get-UsbIds -Verbose
TestMe -Verbose
