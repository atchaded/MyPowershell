<# This script updates VMware VMtool 
The script does not run on a Priv1 machine, but is successful process on a General Realm machine

https://pubs.vmware.com/vsphere-51/index.jsp?topic=%2Fcom.vmware.powercli.cmdletref.doc%2FNew-Snapshot.html
https://www.reddit.com/r/vmware/comments/49flgc/snapshots_quiesce_or_memory_state/
https://www.computerworld.com/article/2879205/data-center/powershell-for-beginners-scripts-and-loops.html?page=6
https://technet.microsoft.com/en-us/library/jj554301.aspx
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parameters_default_values?view=powershell-6
https://blogs.technet.microsoft.com/heyscriptingguy/2011/05/16/add-excellent-comments-to-your-powershell-script/
#>

Param(
  [Parameter(Mandatory=$True,Position=1)]   	# The parameter is mandatory and shouldbe in position 1 
  [string]$VMName								# $VMName   ---  Name of the VM that needs a VMtool update

# [string]$VMVCenterServer						# $VMVCenterServer  ---  Name of the VSphere VCenter Server 
) 												# End of parameter

$VMVCenterServer = "vsvc.nist.gov"

# set-executionpolicy unrestricted 
Set-PowerCLIConfiguration -InvalidCertificateAction Prompt
connect-viserver -server $VMVCenterServer
get-vm $VMName | new-snapshot -Name "B4-VMTUpg" -Description "B4-VMtool upgrade" -Quiesce 

