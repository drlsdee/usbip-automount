function Get-UsbIpCertificate {
    [CmdletBinding()]
    param (
        # Path to the USBIP distributive folder
        [Parameter()]
        [string]
        $Path
    )
    [string]$myName = "$($MyInvocation.MyCommand.Name):"
    Write-Verbose -Message "$myName Starting function..."
    if (-not [System.IO.Directory]::Exists($Path)) {
        Write-Warning -Message "$myName The folder `"$Path`" does not exists! Exiting."
        return $false
    }

    [System.String[]]$libFiles = [System.IO.Directory]::EnumerateFiles($Path, 'USBIPEnum_*.sys')
    if (-not $libFiles) {
        Write-Warning -Message "$myName Driver files were not found in the folder `"$Path`"! Exiting."
        return $false
    }

    [System.String]$libFileCurrent = $libFiles[0]
    Write-Verbose -Message "$myName Getting certificates from file: $($libFileCurrent)"

    [System.Management.Automation.Signature]$fileSignature = Get-AuthenticodeSignature -FilePath $libFileCurrent

    if (-not $fileSignature.SignerCertificate) {
        Write-Warning -Message "$myName The file `"$libFileCurrent`" does not contain a signature! Exiting."
        return $false
    }

    [System.Security.Cryptography.X509Certificates.X509Certificate2]$certSigner = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($fileSignature.SignerCertificate)
    Write-Verbose -Message "$myName Found the certificate `'$($certSigner.Subject)`' with thumbprint $($certSigner.Thumbprint) issued by `'$($certSigner.Issuer)`'. Continue..."
    [System.Security.Cryptography.X509Certificates.X509Store]$trustedIssuers = [System.Security.Cryptography.X509Certificates.X509Store]::new([System.Security.Cryptography.X509Certificates.StoreName]::TrustedPublisher, [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine)
    $trustedIssuers.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    if ($trustedIssuers.Certificates -contains $certSigner) {
        Write-Verbose -Message "$myName The `'$($trustedIssuers.Name)`' store on the local system `'$($env:COMPUTERNAME)`' already contains the certificate with thumbprint `'$($certSigner.Thumbprint)`'. Nothing to do!"
        $trustedIssuers.Close()
        return $true
    }

    Write-Verbose -Message "$myName Adding certificate to the store..."
    $trustedIssuers.Add($certSigner)
    Write-Verbose -Message "$myName Now closing the store and return."
    $trustedIssuers.Close()
    return $true
}
