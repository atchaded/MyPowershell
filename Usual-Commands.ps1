# This script contains the every commands that I run to setup  my environewment 

# The following command create a mapped drive Z: that has all my personal documents
Net use z:  \\elwood.nist.gov\184\users\dba2

# The following command create a mapped drive X: that has the various Divions documents
New-PSDrive –Name “Z” –PSProvider FileSystem –Root “\\elwood.nist.gov\184\users\dba2”
New-PSDrive –Name “X” –PSProvider FileSystem –Root “\\elwood.nist.gov\184\users\dba2\divisions”
Remove-PSDrive –Name “Z” 

<#
$parameters = @{
    Name = "MyDocs"
    PSProvider = "FileSystem"
    Root = "C:\Users\User01\Documents"
    Description = "Maps to my My Documents folder."
}

New-PSDrive @parameters

Name        Provider      Root
----        --------      ----
MyDocs      FileSystem    C:\Users\User01\Documents

$credential= Get-Credential  -Credential dba2
New-PSDrive -Name "Z" -PSProvider FileSystem -Root "C:\ExecFolder\" -credential $credential

 #>
 

# To configure the IdleTimeout for WinRM to 18 seconds use the following command on the remote server: 
winrm set winrm/config/winrs '@{IdleTimeout="18000"}'

<# 
Pause and display the message "Press Enter to continue..."
CMD /c PAUSE
#>

<# How to get the last restart and of a windows service https://www.coretechnologies.com/blog/windows-services/service-start-time/

(Get-EventLog -LogName "System" -Source "Service Control Manager" -EntryType "Information" -Message "*JBossEAP7*running*" -Newest 1).TimeGenerated
#>
(Get-EventLog -LogName "System" -Source "Service Control Manager" -EntryType "Information" -Message "*JBossEAP7*running*" -Newest 1).TimeGenerated


<# -- How to execute a Schudled tasks on windows Server 
Remove JBoss Logs Older Than 90 Days

C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
-command Get-ChildItem -Path "$Env:JBOSS_HOME\standalone\log\*" -Exclude "audit.log" | Where { $_.LastWriteTime -lt ((Get-Date).AddDays(-90).Date) } | ForEach { $name=$_.fullName; Remove-Item -Path $name -Force }
C:\Windows\System32\WindowsPowerShell\v1.0

#>
<#
PowerShell shutdown example
Clear-Host
Stop-Computer -computerName ExchServer
#>