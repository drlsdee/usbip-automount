# ToDo list for Windows USBIP client
## Order
### Create class for USBIP executable
UsbIpExe.ps1
### Install USBIP driver
#### The certificate that the USBIP driver is signed with is usually not in the 'TrustedPublisher' certificate store.
##### Possible solutions:
1.  Create a GPO object. That is beyond our scope.
1.  Extract the certificate chain and import it to the 'TrustedPublisher' store of the 'LocalMachine' scope:
    1.  with GUI;
    1.  with cmdline utils;
    1.  with PowerShell functions, cmdlets and modules. The last may be included in the our tasklist later.
#### Silent driver installation
Postponed. Depends on the previous task.
## TODO
*   Add the function to use class 'UsbIpExe'
*   Add logging to the text file
*   Convert into the PowerShell module
*   Pass events to the Windows EventLog
*   Monitor state of mounted devices
*   ADD RESPONSE TO CLIENT SHUTDOWN OR REBOOT EVENTS! (Just unmount all monuted devices)
*   Additional functions:
    *   Check host availability
    *   Wake-On-Lan if the host exists but probably down
    *   Check usbipd service status on the remote host, start if down
    *   Restart the usbipd service on the remote host if the device was unmounted incorrectly and the service was hanged up.
    *   Unmount devices before the client's VM will suspended by hypervisor engine.
        *   Poll the hypervisor, e.g. SCVMM?
        *   Poll the monitoring engine (SCOM, Zabbix, Prom and whatever you want)?
    *   Re-publish single device (I suspect it should be on the USBIP server, i.e. it is not Windows-task)
 