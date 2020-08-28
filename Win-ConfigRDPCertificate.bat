wmic /namespace:\\root\cimv2\TerminalServices PATH Win32_TSGeneralSetting Set SSLCertificateSHA1Hash="THUMBPRINT" 



netsh http add sslcert ipport=0.0.0.0:<port *1)> certstorename=Root certhash=<thumbprint to certificate *2)> appid={<guid to application *3)>}


[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters] "AllowEncryptionOracle"=dword:00000002


A fatal error occurred while creating a TLS client credential. The internal error state is 10013

The issue and solution isn't about exchange server, its a .Net Framework issue. Although the article is about Exchange Server its the part about configuring .Net that you need.

In short you need to make registry change:

Windows Registry Editor Version 5.00
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v4.0.30319]
"SystemDefaultTlsVersions"=dword:00000001
[HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319]
"SystemDefaultTlsVersions"=dword:00000001



Windows Registry Editor Version 5.00
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v2.0.50727]
"SystemDefaultTlsVersions"=dword:00000001
[HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v2.0.50727]
"SystemDefaultTlsVersions"=dword:00000001
The registry change enables TLS 1.2 for .Net


Enabling Powershell Remoting, Access is denied?

reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f


PoSH Check: Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\ -Name LocalAccountTokenFilterPolicy PoSH Set: Set-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\ -Name LocalAccountTokenFilterPolicy -Value 1 – mlhDev Apr 1 at 18:25 


0

Verify Powershell version is greater than 3.0 Check to upgrade WMF (windows management framework) to 4.0 or to 5.1
FW off or at least windows remote (inbound) rules are on and public.
Verify windows remote service is running in "automatic"
Verify port 5985 is listening (netstat -noa)
Verify no antivirus FW is blocking



SSL Certificate add failed when binding to port

certutil -store My