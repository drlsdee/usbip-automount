@{
    RootModule = 'DscUsbIds.psm1'
    ModuleVersion = '0.0.0.0'
    GUID = '8f228075-6f18-44f1-b153-9244564c3b25'
    Author = 'drlsdee '
    CompanyName = 'Unknown'
    Copyright = '(c) 2020 drlsdee  <tracert0@gmail.com>. All rights reserved.'
    Description = 'Description should be here.'
    PowerShellVersion = '5.1'
    FunctionsToExport = '*'
    CmdletsToExport = '*'
    VariablesToExport = '*'
    AliasesToExport = '*'
    DscResourcesToExport = 'DscUsbIds'
    PrivateData = @{
        PSData = @{
            ProjectUri = 'https://github.com/drlsdee/usbip-automount'
            ReleaseNotes = 'DSC resource ''DscUsbIds'' adds or removes the file ''usb.ids'''
        }
    }
}

