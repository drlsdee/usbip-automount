# Defines the values for the resource's Ensure property.
enum Ensure {
    # The resource must be absent.
    Absent
    # The resource must be present.
    Present
}

# [DscResource()] indicates the class is a DSC resource.
[DscResource()]
class UsbIpIds {
    # Full path to the destination file
    [DscProperty(Key)]
    [string]
    $Path
    
    # Ensure
    [DscProperty(Mandatory)]
    [Ensure]
    $Ensure
    
    # Creation date if file is present
    [DscProperty(NotConfigurable)]
    [Nullable[datetime]]
    $CreationDate

    # File SHA256 hash if the file is present
    [DscProperty(NotConfigurable)]
    [Nullable[string]]
    $SHA256
    
    # Source URI, default is 'http://www.linux-usb.org/usb.ids'
    [DscProperty()]
    [string]
    $SourceUri = 'http://www.linux-usb.org/usb.ids'

    [DscProperty()]
    [string]
    $SourcePath
    
    # Gets the resource's current state.
    [UsbIpIds]
    Get()
    {
        [bool]$fileIsPresent = [UsbIpIds]::CompareFiles($this.SourcePath, $this.Path)

        if ($fileIsPresent) {
            $this.Ensure        = [Ensure]::Present
            $this.CreationDate  = [System.IO.File]::GetCreationTime($this.Path)
            $this.SHA256        = [UsbIpIds]::GetFileHash($this.Path)
        }
        else {
            $this.Ensure        = [Ensure]::Absent
            $this.CreationDate  = $null
            $this.SHA256        = $null
        }
        
        return $this
    }

    # Compares file hashes
    static
    [bool]
    CompareFiles(
        [string]$pathSrc,
        [string]$pathDst
    )
    {
        if
        (
            -not [System.IO.File]::Exists($pathDst)
        )
        {
            [bool]$filesAreEqual = $false
        }
        elseif
        (
            [System.IO.File]::Exists($pathDst) -and `
            (-not [System.IO.File]::Exists($pathSrc))
        )
        {
            [bool]$filesAreEqual = $true
        }
        else
        {
            [string]$hashDst = (Get-FileHash -Path $pathDst -Algorithm SHA256).Hash
            [string]$hashSrc = (Get-FileHash -Path $pathSrc -Algorithm SHA256).Hash
            [bool]$filesAreEqual = ($hashDst -eq $hashSrc)
        }

        return $filesAreEqual
    }
    
    # Sets the desired state of the resource.
    [void]
    Set()
    {
        
    }
    
    # Tests if the resource is in the desired state.
    [bool]
    Test()
    {
        [bool]$fileIsPresent = [UsbIpIds]::CompareFiles($this.SourcePath, $this.Path)

        if ($this.Ensure -eq [Ensure]::Present) {
            return $fileIsPresent
        }
        else {
            return -not $fileIsPresent
        }
    }
}
