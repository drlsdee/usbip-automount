# Defines the values for the resource's Ensure property.
enum Ensure {
    # The resource must be absent.
    Absent
    # The resource must be present.
    Present
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
        # Getting the FileInfo:
        [System.IO.FileInfo]$fileInfo = [System.IO.FileInfo]::new($pathSource)
        # Getting the reference:
        [System.IO.FileInfo]$refInfo = [System.IO.FileInfo]::new($this.FileName)

        # We don't know if the file exists or not. Therefore, we cannot use the [File]::Exists()
        # method. But we can use the [Directory]::Exists() method to recognize if a given path
        # is a folder or file path. If a directory with such fullname does not exist, we assume
        # that the given path is a directory path and append $this.FileName to it.
        # We also expect all source locations to exist.

        # Compare filenames
        if
        ($fileInfo.Name -eq $this.FileName)
        {
            # We assume that the given path is a file path. Although the directory with the same
            # name may exist too. In that case the file with given name does not exist.
            # If we resolve the source path, we expect the source files exist. If we resolve
            # the destination path, and the directory with the target name already exists,
            # THE DIRECTORY WILL BE REMOVED.
            [string]$pathResult = $fileInfo.FullName
        }
        elseif
        (
            ($fileInfo.BaseName -eq $refInfo.BaseName) -and `   # Basenames are equal
            ($null -ne $fileInfo.Extension)                     # and the extension is present
        )
        {
            # We assume that the given path is a file path, again. And the directory may exist too,
            # but we can create the file with the same basename and defined extension.
            # If we resolve the destination path, and the file with the same name already exists,
            # THE FILE WILL BE OVERWRITTEN.
            [string]$pathResult = [System.IO.Path]::ChangeExtension($fileInfo.FullName, $refInfo.Extension)
        }
        else
        {
            # If basenames are equal, but the extension is null;
            # or filenames are not equal at all.
            # Here we expect that the given path is a folder path.
            # And all files should be placed inside that folder.
            [string]$pathResult = [System.IO.Path]::Combine($fileInfo.FullName, $this.FileName)
        }

        # Returning the resulting path:
        return $pathResult
    }

    # Method: returns a path to the temporary folder where the source file should be downloaded.
    # If the file is present, it will be downloaded again anyway.
    [string]
    DownloadFile()
    {
        # Getting the temporary folder:
        [string]$folderTempPath  = [System.IO.Path]::GetTempPath()

        # Getting the temporary filename:
        [string]$fileTempPath = [System.IO.Path]::GetTempFileName()

        # Combining the resulting path:
        [string]$pathResult = [System.IO.Path]::Combine($folderTempPath, $this.FileName)

        # If the file with the same name exists, delete this.
        if ([System.IO.File]::Exists($pathResult)) {
            [System.IO.File]::Delete($pathResult)
        }

        # Create an instance of the web client and download the file.
        [System.Net.WebClient]$webClient = [System.Net.WebClient]::new()
        $webClient.DownloadFile($this.SourceUri, $fileTempPath)

        # If the file downloades successfully, copy them:
        if ([System.IO.File]::Exists($fileTempPath)) {
            [System.IO.File]::Copy($fileTempPath, $pathResult, $true)
        }

        # and remove the temporary file:
        [System.IO.File]::Delete($fileTempPath)

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
        # Removing the file if exists.
        if ([System.IO.File]::Exists($filePathToRemove)) {
            [System.IO.File]::Delete($filePathToRemove)
        }
    }

    # Method: compare files.
    [hashtable]
    CompareFiles()
    {
        [string]$filePathSource = $this.SelectPath()
        [string]$filePathDest = $this.ResolvePath($this.DestinationFolder)

        [System.IO.FileInfo]$fileInfoSource = [System.IO.FileInfo]::new($filePathSource)
        [System.IO.FileInfo]$fileInfoDest = [System.IO.FileInfo]::new($filePathDest)
        

        if
        (
            (-not $fileInfoSource.Exists) -and `
            (-not $fileInfoDest.Exists)
        )
        {
            [string]$checkSumSource = $null
            [string]$checkSumDest = $null
            [bool]$checkSumsAreEqual = $false
        }
        else
        {
            [string]$checkSumSource = (Get-FileHash -Algorithm SHA256 -Path $fileInfoSource.FullName).Hash
            [string]$checkSumDest = (Get-FileHash -Algorithm SHA256 -Path $fileInfoDest.FullName).Hash
            [bool]$checkSumsAreEqual = $checkSumSource -eq $checkSumDest
        }

        if ($checkSumsAreEqual) {
            [Ensure]$resourceState = [Ensure]::Present
        }
        else {
            [Ensure]$resourceState = [Ensure]::Absent
        }

        if ($fileInfoDest.Exists) {
            [Nullable[datetime]]$destCreationDate = $fileInfoDest.CreationTime
        }
        else {
            [Nullable[datetime]]$destCreationDate = $null
        }

        [hashtable]$comparisonResult = @{
            SHA256CheckSum = $checkSumDest
            CreationDate = $destCreationDate
            FullName = $fileInfoDest.FullName
            Length = $fileInfoDest.Length
            DestinationFolder = $fileInfoDest.DirectoryName
            SourcePath = $fileInfoSource.FullName
            Ensure = $resourceState
        }

        return $comparisonResult
    }

    # Method: gets the current resource state
    [UsbIpFiles]
    Get()
    {
        [hashtable]$comparisonResult = $this.CompareFiles()
        $this.SHA256CheckSum = $comparisonResult.SHA256CheckSum
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

class UsbIpExe : UsbIpFiles {
    
}