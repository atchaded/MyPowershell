
Install-PackageProvider -Name NuGet -Force
Import-PackageProvider -Name NuGet -RequiredVersion 2.8.5.208 -Force

Install-Module -Name PowerShellGet

Get-PackageProvider -ListAvailable

Find-Module -Repository DjossePsRepository

Register-PSRepository -Name DjossePsRepository -SourceLocation c:\users\dba11\Documents\PSRepository -InstallationPolicy Trusted

Install-Module -Name microsoft.aspnet.webapi.5.2.7.nupkg -Repository  DjossePsRepository 


