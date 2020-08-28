<# This script updates the HTTPS listener certificate Thumbprint  
it verifies that the WinRM service is running
#>

Get-Service -Name "WinRM"
Get-PSdrive
<#
Name           Used (GB)     Free (GB) Provider      Root                                                                                                                                                                    CurrentLocation
----           ---------     --------- --------      ----                                                                                                                                                                    ---------------
Alias                                  Alias
C                  23.59         75.92 FileSystem    C:\                                                                                                                                                                    Windows\system32
Cert                                   Certificate   \
D                                      FileSystem    D:\
E                   1.79         98.21 FileSystem    E:\
Env                                    Environment
Function                               Function
HKCU                                   Registry      HKEY_CURRENT_USER
HKLM                                   Registry      HKEY_LOCAL_MACHINE
Variable                               Variable
WSMan                                  WSMan

#> 

set-location cert:
Set-Location .\\LocalMachine\
dir

<#

Location   : CurrentUser
StoreNames : {TrustedPublisher, ClientAuthIssuer, Root, UserDS...}

Location   : LocalMachine
StoreNames : {TrustedPublisher, ClientAuthIssuer, Remote Desktop, Root...}

Class of Certiciate Stores

Name : TrustedPublisher
Name : ClientAuthIssuer
Name : Remote Desktop
Name : Root
Name : TrustedDevices
Name : WebHosting
Name : CA
Name : Windows Live ID Token Issuer
Name : REQUEST
Name : AuthRoot
Name : FlightRoot
Name : TrustedPeople
Name : My
Name : SmartCardRoot
Name : Trust
Name : Disallowed
Name : SMS
#>

$servername = $env:computername
Get-ChildItem -Path  .\\LocalMachine\my

<#

PSParentPath: Microsoft.PowerShell.Security\Certificate::LocalMachine\my

Thumbprint                                Subject
----------                                -------
CE0421CFB39B0003311C9CB3CF912C235D3F0E62  CN=NISTIssuingCA03, DC=campus, DC=NIST, DC=GOV
75964F55CA64BE732CB2E9864247BFF3380D60D0  CN=NISTRoot02
31DF2301A72A6E017BF47F3348471FB4508503E5  E=windowshosting@nist.gov, CN=wsacnstd01.campus.nist.gov, OU=OISM, O=National Institute of Standards and Technology, L=Gaithersburg, S=Maryland, C=US

#>

$Cert = (Get-ChildItem -Path "Cert:\LocalMachine\My" | Where {$_.Subject -LIKE "e=windowshosting@*" } )
$Cert

<#
   PSParentPath: Microsoft.PowerShell.Security\Certificate::LocalMachine\My

Thumbprint                                Subject
----------                                -------
31DF2301A72A6E017BF47F3348471FB4508503E5  E=windowshosting@nist.gov, CN=wsacnstd01.campus.nist.gov, OU=OISM, O=National Institute of Standards and Technology, L=Gaithersburg, S=Maryland, C=US

#>

winrm delete winrm/config/Listener?Address=*+Transport=HTTPS
Get-ChildItem -Path "wsman:\localhost\listener"


<#  
 WSManConfig: Microsoft.WSMan.Management\WSMan::localhost\Listener

Type            Keys                                Name
----            ----                                ----
Container       {Transport=HTTPS, Address=*}        Listener_1305953032

#>

New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint –Force
Get-ChildItem -Path "wsman:\localhost\listener"

<#
  WSManConfig: Microsoft.WSMan.Management\WSMan::localhost\Listener

Type            Keys                                Name
----            ----                                ----
Container       {Transport=HTTPS, Address=*}        Listener_1305953032
Container       {Transport=HTTP, Address=*}         Listener_1084132640

By default WinRM HTTP uses port 80.  On Windows 7 and higher the default port is 5985.
By default WinRM HTTPS uses port 443.  On Windows 7 and higher the default port is 5986.

To confirm WinRM is listening on HTTPS type the following:

 winrm enumerate winrm/config/listener


To confirm a computer certificate has been installed use the Certificates MMC add-in or type the following:

Winrm get http://schemas.microsoft.com/wbem/wsman/1/config

If you get the following error message: 

Error number:  -2144108267 0x80338115
    ProviderFault
        WSManFault
             Message = Cannot create a WinRM listener on HTTPS because this machine does not have an appropriate certificate. To be used for SSL, a certificate must have a CN matching the hostname, be appropriate for Server Authentication, and  not be expired, revoked, or self-signed.

Open the certificates MMC add-in and confirm the following attributes are correct:

The date of the computer falls between the "Valid from:" to the "To:" date on the General tab
Host name matches the "Issued to:" on the General tab or it matches one of the "Subject Alternative Name" exactly as displayed on the Details tab.
That the "Enhanced Key Usage" on the Details tab contains "Server authentication"
On the Certification Path tab that the Current Status: is "This certificate is OK"
If you have more than one local computer account server certificate installed confirm the CertificateThumbprint displayed by:

Winrm enumerate winrm/config/listener

is the same Thumbprint on the Details tab of the certificate.




http://simpletechtips101.blogspot.com/2018/09/installing-ca-certificate-to-windows.html
WMI Method


The RDS listener configuration data for  is stored in the Win32_TSGeneralSetting class in WMI under the Root\CimV2\TerminalServices namespace. The thumbprint value is unique to each certificate. and is referenced by the SSLCertificateSHA1Hash property.



Simple Powershell command to get the thumbprint value

#>

Get-Childitem Cert:\LocalMachine\My



(the above command only works if a certificate has been previously imported to the personal folder using mmc snap-in)

     Copy the thumbprint hash value Run the below power shell command in admin mode substituting the highlighted thumbprint value with your thumbprint value of the new certificate.


$path = (Get-WmiObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'").__path

Set-WmiInstance -Path $path -argument @{SSLCertificateSHA1Hash="thumbprintvalue"} 


+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

