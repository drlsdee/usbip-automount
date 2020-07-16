#using module 'C:\Users\Administrator\GitHub\usbip-automount\client-win\usbip\UsbIpIds'
Get-Module -Name 'C:\Users\Administrator\GitHub\usbip-automount\client-win\usbip\UsbIpIds\UsbIpIds.psm1' -ListAvailable -Verbose | Select-Object *
Import-Module -Name 'C:\Users\Administrator\GitHub\usbip-automount\client-win\usbip\UsbIpIds\UsbIpIds.psm1' -Verbose -Force
Get-Module -Name UsbIpIds | select-object *
# Action here
<# 
[UsbIpIds]$testInstance = [UsbIpIds]::new()
$testInstance.Path = 'C:\usbip\usb.ids'
$testInstance.Get()
$testInstance.Test()
 #>
Remove-Module -Name UsbIpIds -Verbose