# This script installs IIS and the features required to
# run West Wind Web Connection.
#
# * Make sure you run this script from a Powershell Admin Prompt!
# * Make sure Powershell Execution Policy is bypassed to run these scripts:
# * YOU MAY HAVE TO RUN THIS COMMAND PRIOR TO RUNNING THIS SCRIPT!

Set-ExecutionPolicy Bypass -Scope Process

# To list all Windows Features: dism /online /Get-Features
# Get-WindowsOptionalFeature -Online 
# LIST All IIS FEATURES: 
# Get-WindowsOptionalFeature -Online | where FeatureName -like 'IIS-*'

$List = @( )

$List += "WebServerRole"    , "WebServer"       , "CommonHTTPFeatures"     , 
         "HTTPErrors"       , "HTTTPRedirect"   , "ApplicationDevelopment" | % { "IIS-$_" }

$List += "NetFX4Extended-ASPNET45"

$List += "NetFXExtensibility45"     , "HealthAndDiagnostics"        , "HTTPLogging"            , 
         "LoggingLibraries"         , "RequestMonitor"              , "HTTPTracing"            ,
         "Security"                 , "RequestFilgering"            , "Performance"            , 
         "WebServerManagementTools" , "IIS6ManagementCompatibility" , "Metabase"               ,
         "ManagementConsole"        , "BasicAuthentication"         , "WindowsAuthentication"  , 
         "StaticContent"            , "DefaultDocument"             , "WebSockets"             ,
         "ApplicationInit"          , "ISAPIExtensions"             , "ISAPIFilter"            , 
         "HTTPCompressionStatic"    , "ASPNET45"                    | % { "IIS-$_" }

Get-WindowsOptionalFeature -Online | Select FeatureName , State | Sort FeatureName | % { 

    ForEach ( $i in $List ) 
    { 
        If ( $i -eq $_.FeatureName -and $_.State -ne "Enabled" ) 
        { 
            Enable-WindowsOptionalFeature -Online -FeatureName $i 
        }
    }
}

# If you need classic ASP (not recommended)
#Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASP


# The following optional components require 
# Chocolatey OR Web Platform Installer to install


# Install UrlRewrite Module for Extensionless Urls (optional)
###  & "C:\Program Files\Microsoft\Web Platform Installer\WebpiCmd-x64.exe" /install /Products:UrlRewrite2 /AcceptEULA /SuppressPostFinish
#choco install urlrewrite -y

# Install WebDeploy for Deploying to IIS (optional)
### & "C:\Program Files\Microsoft\Web Platform Installer\WebpiCmd-x64.exe" /install /Products:WDeployNoSMO /AcceptEULA /SuppressPostFinish
# choco install webdeploy -y

# Disable Loopback Check on a Server - to get around no local Logins on Windows Server
# New-ItemProperty HKLM:\System\CurrentControlSet\Control\Lsa -Name "DisableLoopbackCheck" -Value "1" -PropertyType dword