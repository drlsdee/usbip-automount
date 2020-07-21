@{
    RootModule = 'UsbIpFiles.psm1'
    ModuleVersion = '0.0.0.0'
    GUID = 'a00c8b7b-0ee4-4c0c-b1fa-83fd7ff296c5'
    Author = 'drlsdee '
    CompanyName = 'Unknown'
    Copyright = '(c) 2020 drlsdee  <tracert0@gmail.com>. All rights reserved.'
    Description = 'Description should be here.'
    PowerShellVersion = '5.1'
    FunctionsToExport = '*'
    CmdletsToExport = '*'
    VariablesToExport = '*'
    AliasesToExport = '*'
    DscResourcesToExport = 'UsbIds'
    PrivateData = @{
        PSData = @{
            ProjectUri = 'https://github.com/drlsdee/usbip-automount'
            ReleaseNotes = 'DSC resource ''DscUsbIds'' adds or removes the file ''usb.ids'''
        }
    }
}

