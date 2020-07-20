@{
    RootModule = 'xDscUsbIP.psm1'
    ModuleVersion = '0.0.0.1'
    GUID = 'a487cf9f-a2c9-4963-b8c8-661b7a7e3935'
    Author = 'drlsdee '
    CompanyName = 'Unknown'
    Copyright = '(c) 2020 drlsdee  <tracert0@gmail.com>. All rights reserved.'
    Description = 'DSC resource ''DscUsbIds'' adds or removes the file ''usb.ids''.'
    NestedModules = 'DscResources\DscUsbIds\DscUsbIds.psd1'
    PowerShellVersion = '5.1'
    FunctionsToExport = 'Invoke-DscUsbIds'
    CmdletsToExport = '*'
    VariablesToExport = '*'
    AliasesToExport = '*'
    DscResourcesToExport = '*'
    PrivateData = @{
        PSData = @{
            ProjectUri = 'https://github.com/drlsdee/usbip-automount'
            ReleaseNotes = 'DSC resource ''DscUsbIds'' adds or removes the file ''usb.ids'''
        }
    }
}

