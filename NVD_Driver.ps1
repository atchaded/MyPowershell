<# 
.SYNOPSIS
  The main NVD PowerShell that is used to call all other scripts. Reads script parameter
  default values from "configFile" and can be run to automatically use those defaults or 
  ask the user to verify each parameter value.

.DESCRIPTION
  By using this script to call all other NVD PowerShell scripts, we can store default values
  for all script parameters in the Driver-Config.xml file. All of the NVD scripts as well as their
  parmeters (and default values for those parameters) are stored in the Driver-Config.xml file. The
  NVD_Driver.ps1 script will get the list of parameters for the "scriptName" provided, then for each
  parameter, either use the value provided in the "params" hashtable, the default value from the 
  Driver-Config.xml file, or the value entered manually by the user. Prior to executing any scripts, 
  the NVD_Driver.ps1 script will check the existence and values of the Global variables in the Globals
  section of the Driver-Config.xml file. If any are missing or don't match, NVD_Driver.ps1 will call 
  Declare-Globals.ps1 to set them all.

.PARAMETER configFile
  Name of the XML file that stores all of the script parameter defaults. Can either be a full path or just a file
  name. If only a name is provided, script assumes file exists in same folder. Defaults to "Driver-Config.xml"
.PARAMETER scriptName
  The name of the PowerShell script to run. Required parameter. If not supplied, the script will use Read-Host
  to get ask for a value.
.PARAMETER params
  Harshtable containing parameter names and values to pass to scriptName
.PARAMETER parameters
  Duplicate of params - this way either can be used.
.PARAMETER auto
  Switch indicating whether or not to run in automatic mode. If true, parameter values from
  the congifFile will be used. If false, the user will be able to manually enter values for
  each parameter.

.EXAMPLE
  .\NVD_Driver.ps1
  This will ask the user for the name of the script to be run. If a valid script name is provided,
  each parameter (along with the default value, if there is one), will be provided to the user. For
  each parameter, the user may either choose to accept the default or provide their own value.
.EXAMPLE
  .\NVD_Driver.ps1 -scriptName "FindIn-Files.ps1" -params @{"path"="C:\temp";"token"="ERROR"}
  This will list each of the parameters for the "FindIn-Files.ps1" script other than "path" and "token"
  and provide the user the opportunity to either use the default value found in the "Driver-Config.xml" file
  or manually enter a value. Once a value has been provided for each parameter, the script will show the user
  the command that is going to be run and ask for confirmation to run it. If the Global variables haven't been
  set, or don't match the values in "Driver-Config.xml", it will first run "Declare-Globals.ps1"
.EXAMPLE
  .\NVD_Driver.ps1 -scriptName "Install-Jdk.ps1" -params @{"uninstall"="true"} -auto
  This will automatically run the Install-Jdk.ps1 script using the parameters provided above as well
  as the default parameters found in the "Driver-Config.xml" file. If the Global variables haven't been
  set, or don't match the values in "Driver-Config.xml", it will first run "Declare-Globals.ps1."
  The result will be that the Java JDK will be uninstalled from the machine.
  
.LINK
  https://share.nist.gov/sites/oism/nvd/devwiki/Wiki%20Pages/NVD%20PowerShell%20Scripts.aspx
#>

param(
	[string]$configFile="Driver-Config.xml",
    [string]$scriptName,
    [hashtable]$params,
    [hashtable]$parameters,
    [switch]$auto=$false
)

function processString{
	param([string] $inputString, [string] $retType)
	
    [array]$retArray=@()
    [hashtable]$retHash=@{}
    $inputString=$inputString.TrimStart("@").TrimStart("(").TrimEnd(")")
    $inputString=$inputString.TrimStart("{").TrimEnd("}")
    $inputString=$inputString.Replace("'='","=")
    $inputString=$inputString.Replace("""=""","=")
    $inputString=$inputString.Replace("','",",")
    $inputString=$inputString.Replace(""",""",",")
    $inputString=$inputString.Replace("',",",")
    $inputString=$inputString.Replace(""",",",")
    $inputString=$inputString.Replace("';'",";")
    $inputString=$inputString.Replace(""";""",";")
    $inputString=$inputString.Replace("';",";")
    $inputString=$inputString.Replace(""";",";")
    $inputString=$inputString.TrimStart("'").TrimEnd("'")
    $inputString=$inputString.TrimStart("""").TrimEnd("""")
    if($retType.toLower() -like "hash*"){
        ($inputString -split ";")  | % { if("x$_" -ne "x"){ $retHash.Add((($_.split("="))[0].trim()),(($_.split("="))[1].trim()))}}
        return $retHash
    }
    else{
        ($inputString -split ",") | % { if("x$_" -ne "x"){ $retArray=$retArray += $_ } }
        return $retArray
    }
    return $NULL
}

if(($params.length) -gt ($parmeters.length)){
    $parameters=$params
}
while("x$scriptName" -eq "x"){
    $scriptName = Read-Host "Please enter the name of the script you would like to run"
}
$searchString=$scriptName.Replace("-","").Replace(".ps1","").Replace(".\","")
#Reverted to the old way, since Prod servers might still be running PSv2
#$scriptPath=$PSScriptRoot
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$xmlFile=$configFile
if(-not (Test-Path $xmlFile)){
	$xmlFile = Join-Path $scriptPath $configFile
}
if(-not (Test-Path $xmlFile)){
	Throw "Cannot find XML file: $configFile"
}
[xml]$configFile = Get-Content $xmlFile
$PSScript=$configFile.Configuration.PSScripts.PSScript | where { ($_.id.Replace("-","").Replace(".ps1","").Replace(".\","")) -eq $searchString}
$fullScriptName=$PSScript.id
$dispString=""
$textToHide = @()
foreach($XMLparam in $PSScript.ChildNodes){
    $name=$XMLparam.name
    $type=$XMLparam.type
    $userParam=$parameters.$name
    $defaultParam=$XMLparam.InnerText
    switch -wildcard ($type.toLower()){
        "array" {
            if("x$userParam" -ne "x"){
                $userParamType=$userParam.GetType().isArray
                [array]$value=$null
                if($userParam.GetType().IsArray){
                    $value=$userParam
                    $dispString+="-"+$name+" @("
                    $userParam | % { $dispString+="'$_'," }
                    $dispString=$dispString.TrimEnd(",")
                    $dispString+=") "
                }
                else{
                    [array]$value=processString $userParam $type.toLower()
                    $dispString+="-"+$name+" @("
                    $value | % { $dispString+="'$_'," }
                    $dispString=$dispString.TrimEnd(",")
                    $dispString+=") "
                }
            }
            else{
                $response=""
                if(!$auto){
                    $response=Read-Host "$name ($defaultParam)"
                }
                if("x$response" -ne "x"){
                    [array]$value=processString $response $type.toLower()
                    $dispString+="-"+$name+" @("
                    $value | % { $dispString+="'$_'," }
                    $dispString=$dispString.TrimEnd(",")
                    $dispString+=") "
				}
                else{
                    if($XMLparam.InnerText -ne ""){
                        [array]$value=($XMLparam.InnerText -split ",")
                        $dispString+="-"+$name+" @('"+($XMLparam.InnerText).Replace(",","','")+"') "
                    }
                    else{
                        #$dispString+="-"+$name+" '' "
                    }
                }
            }
        }
        "hash*"{
            if($userParam.count -gt 0){
                [hashtable]$value=$null
                if(($userParam.GetType().Name).StartsWith("Hash")){
                    $value=$userParam
                    $dispString+="-"+$name+" @{"
                    $userParam.keys | % { $dispString+="'$_'"+"='"+$userParam.$_+"';" }
                    $dispString=$dispString.TrimEnd(";")
                    $dispString+="} "
                }
                else{
                    $value=processString $userParam $type.toLower()
                    $dispString+="-"+$name+" @{"
                    $value.keys | % { $dispString+="'$_'"+"='"+$value.$_+"';" }
                    $dispString=$dispString.TrimEnd(";")
                    $dispString+="} "
                }
            }
            else{
                $response=""
                if(!$auto){
                    $response=Read-Host "$name ($defaultParam)"
                }
                if("x$response" -ne "x"){
                    [hashtable]$value=processString $response $type.toLower()
                    $response=$response.TrimStart("@")
                    $response=$response.TrimStart("[")
                    $response=$response.TrimEnd("]")
                    $dispString+="-"+$name+" @{"""+(($response  -replace '(\s*),(\s*)', ',') -replace '(\s*)=(\s*)', '=').Replace(";",""";""").Replace("=","""=""")+"""} "
                }
                else{
                    [hashtable]$value=@{}
                    if($XMLparam.InnerText -ne ""){
                        ($XMLparam.InnerText -split ";")  | % {$value.Add((($_.split("="))[0].trim()),(($_.split("="))[1].trim()))}
                        $dispString+="-"+$name+" @{"""+(($XMLparam.InnerText  -replace '(\s*),(\s*)', ',') -replace '(\s*)=(\s*)', '=').Replace(";",""";""").Replace("=","""=""")+"""} "
                    }
                    else{
                        #$dispString+="-"+$name+" '' "
                    }
                }
            }
        }
        "int*" {
            if("x$userParam" -ne "x"){
                [int]$value=$userParam
                $dispString+="-"+$name+" '$value' "
            }
            else{
                $response=""
                if(!$auto){
                    $response=Read-Host "$name ($defaultParam)"
                }
                if("x$response" -ne "x"){
                    $dispString+="-"+$name+" '$response' "
                }
                else{
                    [int]$value=$XMLparam.InnerText
                    $dispString+="-"+$name+" '$value' "
                }
            }
        }
        "double" {
            if("x$userParam" -ne "x"){
                [double]$value=Invoke-Expression $userParam
                $dispString+="-"+$name+" '$value' "
            }
            else{
                $response=""
                if(!$auto){
                    $response=Read-Host "$name ($defaultParam)"
                }
                if("x$response" -ne "x"){
                    [double]$value=Invoke-Expression $response
                    $dispString+="-"+$name+" '$value' "
                }
                else{
                    $temp=$XMLParam.InnerText
                    [double]$value=Invoke-Expression $temp
                    $dispString+="-"+$name+" '$value' "
                }
            }
        }
        "bool*" {
            $text=""
            if("x$userParam" -ne "x"){
                $text=$userParam
                if($text.GetType().Name -eq "String"){
                    $text=$text.toLower()
                }
            }
            else{
                $response=""
                if(!$auto){
                    $response=Read-Host "$name ($defaultParam)"
                }
                if("x$response" -ne "x"){
                    $text=$response.toLower()
                }
                else{
                    $text=$XMLparam.InnerText.toLower()
                }
            }
            if(($text -eq $true) -OR ($text -eq "1") -or ($text -eq "true")){
                [bool]$value=$true
                $text="true"
            }
            else{
                [bool]$value=$false
                $text="false"
            }
            $dispString+="-"+$name+":$"+$text+" "
        }
		"pass*" {
            if("x$userParam" -ne "x"){
                $dispString+="-"+$name+" '$userParam' "
				$textToHide += $userParam
            }
            else{
                $response=""
                if(!$auto){
					if("x$defaultParam" -eq "x"){
						$response=& $scriptPath\NVD_Driver.ps1 -scriptName "Prompt-Password.ps1" -parameters @{"promptText"="$name ($defaultParam)" } -auto:$true
					}
					else{
						$response=& $scriptPath\NVD_Driver.ps1 -scriptName "Prompt-Password.ps1" -parameters @{"promptText"="$name ($defaultParam)";"password"="$defaultParam" } -auto:$true
					}
                }
                if("x$response" -ne "x"){
                    $dispString+="-"+$name+" '$response' "
					$textToHide += $response
                }
                else{
                    [string]$value=$XMLparam.InnerText
                    $dispString+="-"+$name+" '$value' "
					$textToHide += $value
                }
            }
		}
        default {
            if("x$userParam" -ne "x"){
                $userParam = $userParam.Replace("'","''")
                $dispString+="-"+$name+" '$userParam' "
            }
            else{
                $response=""
                if(!$auto){
                    $response=Read-Host "$name ($defaultParam)"
                }
                if("x$response" -ne "x"){
                    $response = $response.Replace("'","''")
                    $dispString+="-"+$name+" '$response' "
                }
                else{
                    [string]$value=$XMLparam.InnerText
                    $value = $value.Replace("'","''")
                    $dispString+="-"+$name+" '$value' "
                }
            }
        }
    } 
    
}
if("x$fullScriptName" -ne "x"){
	$script=Join-Path $scriptPath $fullScriptName
	$expression="'$script' $dispString"
    if(!$auto){
		foreach ($toHide in $textToHide) {
			$dispString = $dispString.Replace($toHide,"********")
		}
        Write-Host ""
		Write-Host "Ready to run: $script $dispString"
        $response=Read-Host "Run?"
    }
    else{
        $response="y"
    }
    if(($response.toLower() -eq "y") -OR ($response.toLower() -eq "yes")){
        $declare = $false
        if($fullScriptName -notlike "Declare-Globals.ps1"){
            foreach($node in $configFile.Configuration.Globals.ChildNodes) {
                $varName = $node.Name
                $varValue = $node.InnerText
                
                $currentValue = Get-Variable -Name $varName -Scope Global -ValueOnly -ErrorAction SilentlyContinue
                if(($currentValue -eq $NULL) -OR ($currentValue -ne $varValue)){
                    Write-Host "Global $varname is NULL or different '$currentValue' vs. '$varValue'"
                    $declare = $true
                    break
                }
            }
        }
        if($declare){
            Write-Host -ForegroundColor  "Yellow" "Running Declare-Globals.ps1"
            & $scriptPath\NVD_Driver.ps1 -scriptName "Declare-Globals.ps1" -auto:$true
        }
        
        Invoke-Expression "& $expression"
    }
    else{
        Write-Host "Aborting."
    }        
}
else{
    Write-Host "The script name that you entered ('$scriptName') was not found."
}
