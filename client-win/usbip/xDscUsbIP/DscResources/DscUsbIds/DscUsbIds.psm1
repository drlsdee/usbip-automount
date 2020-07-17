# Defines the values for the resource's Ensure property.
enum Ensure {
    # The resource must be absent.
    Absent
    # The resource must be present.
    Present
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

    # Source URI (default is 'http://www.linux-usb.org/usb.ids')
    [DscProperty()]
    [string] $SourceUri = 'http://www.linux-usb.org/usb.ids'

    # Source path (if the source file is placed on the filesystem)
    [DscProperty()]
    [string] $SourcePath

    # A method resolves folder path to file path
    [string]
    ResolvePath(
        [string]$srcPath
    )
    {
        [string]$srcPath = [System.IO.Path]::GetFullPath($srcPath)
        [string]$fileBaseName = 'usb'
        [string]$fileExt = 'ids'
        [string]$fileName = "$($fileBaseName).$($fileExt)"
        
        if
        ([System.IO.Path]::GetFileName($srcPath) -eq $fileName)
        {
            [string]$pathResult = $srcPath
        }
        elseif
        (
            [System.IO.Path]::GetFileNameWithoutExtension($srcPath) -eq [System.IO.Path]::GetFileNameWithoutExtension($fileName)
        )
        {
            [string]$pathResult = [System.IO.Path]::ChangeExtension($srcPath, $fileExt)
        }
        elseif ([System.IO.File]::Exists($srcPath)) {
            [string]$folderName = [System.IO.Path]::GetDirectoryName($srcPath)
            [string]$pathResult = [System.IO.Path]::Combine($folderName, $fileName)
        }
        else {
            [string]$pathResult = [System.IO.Path]::Combine($srcPath, $fileName)
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
        [string]$folderPath = [System.IO.Path]::GetDirectoryName($pathDst)
        if (-not [System.IO.Directory]::Exists($folderPath)) {
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
        if ([System.IO.File]::Exists($pathToRemove)) {
            [System.IO.File]::Delete($pathToRemove)
        }

        # Get directory path
        [string]$dirToRemove = [System.IO.Path]::GetDirectoryName($pathToRemove)

        # Removing the directory and all empty parents
        if ([System.IO.Directory]::Exists($dirToRemove)) {

            # Check if the folder is empty
            [string[]]$dirContent = [System.IO.Directory]::GetFileSystemEntries($dirToRemove)
            [bool]$dirEmpty = ($dirContent.Count -eq 0)

            do {
                # Check if the folder is empty
                [string[]]$dirContent = [System.IO.Directory]::GetFileSystemEntries($dirToRemove)
                [bool]$dirEmpty = ($dirContent.Count -eq 0)
                
                if ($dirEmpty) {
                    # Get parent
                    [string]$dirNameParent = [System.IO.Path]::GetDirectoryName($dirToRemove)
                    # Removing the current directory
                    [System.IO.Directory]::Delete($dirToRemove)
                    # Switch to the parent
                    $dirToRemove = $dirNameParent
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
        [string]$tempPath                   = [System.IO.Path]::Combine($tempFolder, 'usb.ids')
        [System.Net.WebClient]$webClient    = [System.Net.WebClient]::new()
        $webClient.DownloadFile($srcUri, $tempPath)
        return $tempPath
    }

    [hashtable]
    CompareFiles()
    {
        # Getting the source file
        if ($this.SourcePath)
        {
            #[string]$sourceFilePath = $this.SourcePath
            [string]$sourceFilePath = $this.ResolvePath($this.SourcePath)
        }
        else {
            [string]$sourceFilePath = $this.DownloadTemp($this.SourceUri)
        }

        # Getting the source file hash
        if ([System.IO.File]::Exists($sourceFilePath)) {
            [string]$srcFileHash    = (Get-FileHash -Path $sourceFilePath -Algorithm SHA256).Hash
        }
        else {
            [string]$srcFileHash    = $null
        }

        # Checking if the destination file exists
        #[string]$destFilePath       = [System.IO.Path]::Combine($this.DestinationFolder, 'usb.ids')
        [string]$destFilePath       = $this.ResolvePath($this.DestinationFolder)
        if ([System.IO.File]::Exists($destFilePath)) {
            [bool]$destFileExists   = $true
            [string]$destFileHash   = (Get-FileHash -Path $destFilePath -Algorithm SHA256).Hash
            [Nullable[datetime]]$destFileDate = [System.IO.File]::GetCreationTime($destFilePath)
        }
        else {
            [bool]$destFileExists   = $false
            [string]$destFileHash   = $null
            [Nullable[datetime]]$destFileDate = $null
        }

        # Comparing hashes
        if  ( ($null -eq $srcFileHash) -and ($null -eq $destFileHash) )
        {
            [bool]$filesAreEqual    = $false
        }
        else {
            [bool]$filesAreEqual    = ($srcFileHash -eq $destFileHash)
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
            CreationDate            = $destFileDate
            CheckSum                = $destFileHash
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