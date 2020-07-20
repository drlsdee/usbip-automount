# Defines the values for the resource's Ensure property.
enum Ensure {
    # The resource must be absent.
    Absent
    # The resource must be present.
    Present
}

class UsbIpFileInfo {
    # Property: The full path to the file
    [string]
    $FullName

    # Property: The full path to the folder containing the file
    [string]
    $DirectoryName

    # Property: The file creation date. For reference only. Does not affect the comparison result.
    [Nullable[datetime]]
    $CreationDate

    # Property: the file SHA256 checksum.
    [string]
    $SHA256

    # Property: the file length in bytes.
    [int]
    $Length

    # Method: Fill the file properties
    [void]
    GetFileInfo(
        [string]$filePath
    )
    {
        [System.IO.FileInfo]$fileInfo   = [System.IO.FileInfo]::new($filePath)
        $this.FullName                  = $fileInfo.FullName
        $this.DirectoryName             = $fileInfo.DirectoryName
        $this.Length                    = $fileInfo.Length
        $this.CreationDate              = $fileInfo.CreationTime
        $this.SHA256                    = (Get-FileHash -Algorithm SHA256 -Path $fileInfo.FullName).Hash
    }

    # Method: Fill the file properties with null or zeroes
    [void]
    GetNullInfo(
        [string]$filePath
    )
    {
        $this.FullName                  = [System.IO.Path]::GetFullPath($filePath)
        $this.DirectoryName             = [System.IO.Path]::GetDirectoryName($filePath)
        $this.SHA256                    = $null
        $this.CreationDate              = $null
        $this.Length                    = $null
    }

    # Constructor:
    UsbIpFileInfo(
        [string]$filePath
    )
    {
        if ([System.IO.File]::Exists($filePath))
        {
            $this.GetFileInfo($filePath)
        }
        else {
            $this.GetNullInfo($filePath)
        }
    }
}

[DscResource()]
class DscUsbIds {
    # A path to destination folder.
    # The folder where the file 'usb.ids' is placed should be assigned as the 'WorkingDirectory'
    # in the 'usbip.exe' startup parameters ([ProcessStartInfo])
    [DscProperty(Key)]
    [string] $DestinationFolder
    
    # Mandatory indicates the property is required and DSC will guarantee it is set.
    [DscProperty(Mandatory)]
    [Ensure] $Ensure
    
    # Creation date of the file 'usb.ids' (if present)
    [DscProperty(NotConfigurable)]
    [Nullable[datetime]] $CreationDate

    # SHA256 hash of the file 'usb.ids' (if present)
    [DscProperty(NotConfigurable)]
    [string] $CheckSum

    # Full path to the destination file
    [DscProperty(NotConfigurable)]
    [string] $DestinationFile

    # Source URI (default is 'http://www.linux-usb.org/usb.ids')
    [DscProperty()]
    [string] $SourceUri = 'http://www.linux-usb.org/usb.ids'

    # Source path (if the source file is placed on the filesystem)
    [DscProperty()]
    [string] $SourcePath

    # Just a filename.
    [DscProperty(NotConfigurable)]
    [string] $FileName = 'usb.ids'

    # A method returns either source file path (if given in params) or a temporary downloaded file path
    [string]
    SelectPath()
    {
        if ($this.SourcePath) {
            [string]$pathToReturn = $this.ResolvePath($this.SourcePath)
        }
        else {
            [string]$pathToReturn = $this.DownloadTemp($this.SourceUri)
        }
        return $pathToReturn
    }

    # A method resolves folder path to file path
    [string]
    ResolvePath(
        [string]$srcPath
    )
    {
        [string]$srcPath        = [System.IO.Path]::GetFullPath($srcPath)
        [string]$fileBaseName   = [System.IO.Path]::GetFileNameWithoutExtension($this.FileName)
        [string]$fileExt        = [System.IO.Path]::GetExtension($this.FileName)
        
        if
        ([System.IO.Path]::GetFileName($srcPath) -eq $this.FileName)
        {
            [string]$pathResult = $srcPath
        }
        elseif
        (
            [System.IO.Path]::GetFileNameWithoutExtension($srcPath) -eq $fileBaseName
        )
        {
            [string]$pathResult = [System.IO.Path]::ChangeExtension($srcPath, $fileExt)
        }
        elseif
        (
            [System.IO.File]::Exists($srcPath)
        )
        {
            [string]$folderName = [System.IO.Path]::GetDirectoryName($srcPath)
            [string]$pathResult = [System.IO.Path]::Combine($folderName, $this.FileName)
        }
        else {
            [string]$pathResult = [System.IO.Path]::Combine($srcPath, $this.FileName)
        }

        return $pathResult
    }

    # A method creates target directory if not exists.
    [void]
    CreateFile(
        [string]$pathSrc,
        [string]$pathDst
    )
    {
        [string]$folderPath     = [System.IO.Path]::GetDirectoryName($pathDst)
        if
        (
            -not [System.IO.Directory]::Exists($folderPath)
        )
        {
            [System.IO.Directory]::CreateDirectory($folderPath)
        }
        [System.IO.File]::Copy($pathSrc, $pathDst, $true)
    }

    [void]
    RemoveRecurse(
        [string]$pathToRemove
    )
    {
        # Removing the file if exists
        if
        (
            [System.IO.File]::Exists($pathToRemove)
        )
        {
            [System.IO.File]::Delete($pathToRemove)
        }

        # Get directory path
        [string]$dirToRemove = [System.IO.Path]::GetDirectoryName($pathToRemove)

        # Removing the directory and all empty parents
        if ([System.IO.Directory]::Exists($dirToRemove)) {

            # Check if the folder is empty
            [string[]]$dirContent           = [System.IO.Directory]::GetFileSystemEntries($dirToRemove)
            [bool]$dirEmpty                 = ($dirContent.Count -eq 0)

            do {
                # Check if the folder is empty
                [string[]]$dirContent       = [System.IO.Directory]::GetFileSystemEntries($dirToRemove)
                [bool]$dirEmpty             = ($dirContent.Count -eq 0)
                
                if ($dirEmpty) {
                    # Get parent
                    [string]$dirNameParent  = [System.IO.Path]::GetDirectoryName($dirToRemove)
                    # Removing the current directory
                    [System.IO.Directory]::Delete($dirToRemove)
                    # Switch to the parent
                    $dirToRemove            = $dirNameParent
                }
            } while ($dirEmpty)
        }
    }

    # A method downloads the source file to the temp folder and returns the path to the downloaded file.
    [string]
    DownloadTemp(
        [string]$srcUri
    )
    {
        [string]$tempFolder                 = [System.IO.Path]::GetTempPath()
        [string]$tempPath                   = [System.IO.Path]::Combine($tempFolder, $this.FileName)
        [System.Net.WebClient]$webClient    = [System.Net.WebClient]::new()
        $webClient.DownloadFile($srcUri, $tempPath)
        return $tempPath
    }

    [hashtable]
    CompareFiles()
    {
        # Getting the source file
        [string]$sourceFilePath     = $this.SelectPath()
        [string]$destFilePath       = $this.ResolvePath($this.DestinationFolder)

        [UsbIpFileInfo]$fileInfoSource = [UsbIpFileInfo]::new($sourceFilePath)
        [UsbIpFileInfo]$fileInfoDest = [UsbIpFileInfo]::new($destFilePath)

        if
        (
            ($null -eq $fileInfoSource.SHA256) -and `
            ($null -eq $fileInfoDest.SHA256)
        )
        {
            [bool]$filesAreEqual    = $false
        }
        else {
            [bool]$filesAreEqual    = $fileInfoDest.SHA256 -eq $fileInfoSource.SHA256
        }

        # Getting ensure state
        if  ($filesAreEqual)
        {
            [Ensure]$fileState      = [Ensure]::Present
        }
        else
        {
            [Ensure]$fileState      = [Ensure]::Absent
        }

        [hashtable]$compareResult   = @{
            ResourceState           = $fileState
            Source                  = $sourceFilePath
            Destination             = $destFilePath
            CreationDate            = $fileInfoDest.CreationDate
            CheckSum                = $fileInfoDest.SHA256
        }
        return $compareResult
    }
    
    # Gets the resource's current state.
    [DscUsbIds]
    Get()
    {
        [hashtable]$compareResult   = $this.CompareFiles()
        $this.Ensure                = $compareResult.ResourceState
        $this.CreationDate          = $compareResult.CreationDate
        $this.CheckSum              = $compareResult.CheckSum
        $this.SourcePath            = $compareResult.Source
        $this.DestinationFile       = $compareResult.Destination
        # Return this instance or construct a new instance.
        return $this
    }
    
    # Sets the desired state of the resource.
    [void]
    Set()
    {
        [hashtable]$compareResult   = $this.CompareFiles()
        if ($this.Ensure -eq [Ensure]::Absent) {
            if ($compareResult.CheckSum) {
                $this.RemoveRecurse($compareResult.Destination)
            }
        }
        else {
            $this.CreateFile($compareResult.Source, $compareResult.Destination)
        }
    }
    
    # Tests if the resource is in the desired state.
    [bool]
    Test()
    {
        [hashtable]$compareResult   = $this.CompareFiles()
        [Ensure]$resourceState      = $compareResult.ResourceState
        [bool]$testResult           = ($this.Ensure -eq $resourceState)
        return $testResult
    }
}