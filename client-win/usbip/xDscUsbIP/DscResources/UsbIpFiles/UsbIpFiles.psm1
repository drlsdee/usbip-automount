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

class UsbIpFiles {
    # Property: full path to the destination folder. Must be a key property in DSC resources.
    [DscProperty(Key)]
    [string]
    $DestinationFolder

    # Property: ensures that the resource is in desired state.
    [DscProperty(Mandatory)]
    [Ensure]
    $Ensure

    # Property: a path to the source file on the filesystem or in the network location.
    # Expected a full path to the source file. If path given here is a folder path, we will try to resolve it
    # using "$this.FileName".
    [DscProperty()]
    [string]
    $SourcePath

    # Property: an URI from where the source file should be downloaded.
    # Expected that the URI ends with the source file name. If not, we will try to add "$this.FileName".
    [DscProperty()]
    [string]
    $SourceUri

    # Property: destination file name. The name will be defined in each of the child classes.
    [DscProperty(NotConfigurable)]
    [string]
    $FileName

    # Property: absolute path to the destination file
    [DscProperty(NotConfigurable)]
    [string]
    $FullName

    # Property: file length in bytes
    [DscProperty(NotConfigurable)]
    [int]
    $Length

    # Property: SHA256 checksum of the source file
    [DscProperty(NotConfigurable)]
    [string]
    $SHA256CheckSum

    # Property: The file creation date. For reference only. Does not affect the comparison result.
    [DscProperty(NotConfigurable)]
    [Nullable[datetime]]
    $CreationDate

    # Method: returns the full path to the file on the filesystem as it expected.
    [string]
    ResolvePath(
        [string]
        $pathSource
    )
    {
        # Getting the absolute path:
        [string]$pathSource = [System.IO.Path]::GetFullPath($pathSource)
        # Getting the filename from the given path:
        [string]$fileNameDef = [System.IO.Path]::GetFileName($pathSource)

        # Getting the basename from the given path:
        [string]$baseNameDef = [System.IO.Path]::GetFileNameWithoutExtension($pathSource)
        # and getting the file basename from the class properties:
        [string]$baseNameProp = [System.IO.Path]::GetFileNameWithoutExtension($this.FileName)

        # Getting the file extension from the given path:
        [string]$fileExtDef = [System.IO.Path]::GetExtension($pathSource)
        # and getting the file extension from the class properties:
        [string]$fileExtProp = [System.IO.Path]::GetExtension($this.FileName)

        # We don't know if the file exists or not. Therefore, we cannot use the [File]::Exists()
        # method. But we can use the [Directory]::Exists() method to recognize if a given path
        # is a folder or file path. If a directory with such fullname does not exist, we assume
        # that the given path is a directory path and append $ this.FileName to it.
        # We also expect all source locations to exist.

        <# if ([System.IO.Directory]::Exists($pathSource)) {
            # The given path is probably a directory path.
            # Yes, the file with the same name may exist too.
        } #>

        # Compare filenames
        if
        ($fileNameDef -eq $this.FileName)
        {
            # We assume that the given path is a file path. Although the directory with the same
            # name may exist too. In that case the file with given name does not exist.
            # If we resolve the source path, we expect the source files exist. If we resolve
            # the destination path, and the directory with the target name already exists,
            # THE DIRECTORY WILL BE REMOVED.
            [string]$pathResult = $pathSource
        }
        elseif
        (
            ($baseNameDef -eq $baseNameProp) -and ` # Basenames are equal
            ($null -ne $fileExtDef)                 # and the extension is present
        )
        {
            # We assume that the given path is a file path, again. And the directory may exist too,
            # but we can create the file with the same basename and defined extension.
            # If we resolve the destination path, and the file with the same name already exists,
            # THE FILE WILL BE OVERWRITTEN.
            [string]$pathResult = [System.IO.Path]::ChangeExtension($pathSource, $fileExtProp)
        }
        else
        {
            # If basenames are equal, but the extension is null;
            # or filenames are not equal at all.
            # Here we expect that the given path is a folder path.
            # And all files should be placed inside that folder.
            [string]$pathResult = [System.IO.Path]::Combine($pathSource, $this.FileName)
        }

        # Returning the resulting path:
        return $pathResult
    }

    # Method: returns a path to the temporary folder where the source file should be downloaded.
    # If the file is present, it will be downloaded again anyway.
    [string]
    DownloadFile()
    {
        # Getting the temporary file name. It will be a folder!
        [string]$folderTempPath  = [System.IO.Path]::GetTempFileName()

        # Combining the resulting path:
        [string]$pathResult = [System.IO.Path]::Combine($folderTempPath, $this.FileName)

        # If the files with the same names exist, delete them.
        @(
            $folderTempPath,
            $pathResult
        ).ForEach({
            if ([System.IO.File]::Exists($_)) {
                [System.IO.File]::Delete($_)
            }
        })

        # If the directory does not exist, create this.
        if (-not [System.IO.Directory]::Exists($folderTempPath)) {
            # I just assign the result of the directory creation
            # to the $null to prevent unwanted output.
            $null = [System.IO.Directory]::CreateDirectory($folderTempPath)
        }

        # Create an instance of the web client and download the file.
        [System.Net.WebClient]$webClient = [System.Net.WebClient]::new()
        $webClient.DownloadFile($this.SourceUri, $pathResult)

        # Returning the resulting path:
        return $pathResult
    }

    # Method: returns either source file path (if given in params) or a temporary path to the downloaded file.
    [string]
    SelectPath()
    {
        if ($this.SourcePath) {
            [string]$pathResult = $this.ResolvePath($this.SourcePath)
        }
        else {
            [string]$pathResult = $this.DownloadFile()
        }
        return $pathResult
    }

    # Method: copies the file from source location to the destination. If the destination folder
    # does not exist, the method creates it recursively.
    [void]
    CreateFile(
        [string]
        $pathSource,

        [string]
        $pathDestination
    )
    {
        # Getting the folder name.
        [string]$folderDestination = [System.IO.Path]::GetDirectoryName($pathDestination)

        # If the file with the same name exists, delete this.
        if ([System.IO.File]::Exists($folderDestination)) {
            [System.IO.File]::Delete($folderDestination)
        }

        # If the directory does not exist, create this.
        if (-not [System.IO.Directory]::Exists($folderDestination)) {
            $null = [System.IO.Directory]::CreateDirectory($folderDestination)
        }

        # Copy file:
        [System.IO.File]::Copy($pathSource, $pathDestination, $true)
    }

    # Method: deletes the file, the folder it was placed in, and all parent folders if these folders are empty.
    [void]
    DeleteFile(
        [string]
        $filePathToRemove
    )
    {
        # Getting the drive letter:
        #[string]$pathRoot = [System.IO.Path]::GetPathRoot($filePathToRemove)
        # Removing the file if exists.
        if ([System.IO.File]::Exists($filePathToRemove)) {
            [System.IO.File]::Delete($filePathToRemove)
        }
    }

    # Method: gets fileinfo for comparison.
    [UsbIpFileInfo]
    GetFileInfo(
        [string]$filePath
    )
    {
        [UsbIpFileInfo]$fileInfo = [UsbIpFileInfo]::new($filePath)
        return $fileInfo
    }

    # Method: compare files.
    [hashtable]
    CompareFiles()
    {
        [string]$filePathSource = $this.SelectPath()
        [string]$filePathDest = $this.ResolvePath($this.DestinationFolder)

        [UsbIpFileInfo]$fileInfoSource = $this.GetFileInfo($filePathSource)
        [UsbIpFileInfo]$fileInfoDest = $this.GetFileInfo($filePathDest)

        if
        (
            ($null -eq $fileInfoSource.SHA256) -and `
            ($null -eq $fileInfoDest.SHA256)
        )
        {
            [bool]$checkSumsAreEqual = $null
        }
        else
        {
            [bool]$checkSumsAreEqual = $fileInfoDest.SHA256 -eq $fileInfoSource.SHA256
        }

        if ($checkSumsAreEqual) {
            [Ensure]$resourceState = [Ensure]::Present
        }
        else {
            [Ensure]$resourceState = [Ensure]::Absent
        }

        [hashtable]$comparisonResult = @{
            CheckSum = $fileInfoDest.SHA256
            CreationDate = $fileInfoDest.CreationDate
            FullName = $fileInfoDest.FullName
            Length = $fileInfoDest.Length
            DestinationFolder = $fileInfoDest.DirectoryName
            SourcePath = $filePathSource
            Ensure = $resourceState
        }

        return $comparisonResult
    }

    # Method: gets the current resource state
    [UsbIpFiles]
    Get()
    {
        [hashtable]$comparisonResult = $this.CompareFiles()
        $this.SHA256CheckSum = $comparisonResult.CheckSum
        $this.FullName = $comparisonResult.FullName
        $this.CreationDate = $comparisonResult.CreationDate
        $this.Ensure = $comparisonResult.Ensure
        $this.SourcePath = $comparisonResult.SourcePath

        return $this
    }

    # Method: tests the current resource state
    [bool]
    Test()
    {
        [hashtable]$comparisonResult = $this.CompareFiles()
        [Ensure]$stateTested = $comparisonResult.Ensure
        [bool]$testResult = $this.Ensure -eq $stateTested
        return $testResult
    }

    # Method: sets the resource in the desired state
    [void]
    Set()
    {
        [hashtable]$comparisonResult = $this.CompareFiles()
        if ($this.Ensure -eq [Ensure]::Absent) {
            $this.DeleteFile($comparisonResult.FullName)
        }
        else {
            $this.CreateFile($comparisonResult.SourcePath, $comparisonResult.FullName)
        }
    }
}

# DSC resource ensures the file 'usb.ids'
[DscResource()]
class UsbIds : UsbIpFiles {
    # Property: an URI from where the source file should be downloaded.
    # Expected that the URI ends with the source file name. If not, we will try to add "$this.FileName".
    #[DscProperty()]
    #[string]
    #$SourceUri = 'http://www.linux-usb.org/usb.ids'

    # Property: destination file name. The name will be defined in each of the child classes.
    #[DscProperty(NotConfigurable)]
    #[string]
    #$FileName = 'usb.ids'

    # Method: returns either source file path (if given in params) or a temporary path to the downloaded file.
    [string]
    SelectPath()
    {
        if (-not $this.SourceUri) {
            $this.SourceUri = 'http://www.linux-usb.org/usb.ids'
        }

        if (-not $this.FileName) {
            $this.FileName = 'usb.ids'
        }

        if ($this.SourcePath) {
            [string]$pathResult = $this.ResolvePath($this.SourcePath)
        }
        else {
            [string]$pathResult = $this.DownloadFile()
        }
        return $pathResult
    }
}
