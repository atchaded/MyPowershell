<# 
.SYNOPSIS
    Reaches out to servers, stops the JBoss service, calls Win Scheduled Task to get latest
    WAR files, then starts the JBoss service. 

.DESCRIPTION
    Reaches out to each server in servers list (param), if the "serviceName" param is not "NONE"
	it stops the JBoss service (using the service name in the serviceName param), calls Windows 
	Scheduled Task (using the task name in the schedTaskName param) to get latest WAR files, then 
	(optionally) starts the JBoss service. The param 'section' can be used to just run the first 
	part (Stop JBoss, Deploy WAR Files), or the second part (Start JBoss). 

.PARAMETER servers
    List of servers on which JBoss is running and should be stopped, deployed, re-started
.PARAMETER serviceName
    Name of the JBoss Windows service running on each of the servers. Set to "NONE" to skip
	stopping and starting the JBoss service. 
.PARAMETER schedTaskName
    Name of the Windows Scheduled Task to run on each server to get the latest JBoss WAR file.
    To skip the step where this script calls the Windows Scheduled Task to deploy the WAR file, ]
    enter a value of "skip" for this parameter.
.PARAMETER section
    Flag allowing this script to be utilized in separate pieces - piece 1: stop JBoss and deploy
    piece 2: start Jboss and monitor for ".deployed" or ".failed" files. 
.PARAMETER filterPrefix
    String indicating the prefix used to filter WAR files. Defaults to "web" (for NVD), but could
	also be "800-53" (for 800-53)

.EXAMPLE
    .\Deploy-Jboss.ps1 -servers "nvd-int-admin","nvd-int-service","nvd-int-web" -serviceName 
    "JBOSSEAP6" -schedTaskName "Deploy WAR File" 
    Stops the Windows service "JBOSSEAP6" on each server listed, calls the Windows scheduled 
    task "Deploy WAR File" on each server listed to get the latest WAR file. Once the WAR file 
    has been updated, starts the Windows service "JBOSSEAP6" and monitors for ".deployed" and 
    ".failed" files
.EXAMPLE
    .\Deploy-Jboss.ps1 -servers "nvd-int-admin","nvd-int-service","nvd-int-web" -serviceName 
    "JBOSSEAP6" -schedTaskName "Deploy WAR File" -section "first"
    Stops the Windows service "JBOSSEAP6" on each server listed, calls the Windows scheduled 
    task "Deploy WAR File" on each server listed to get the latest WAR file.
.EXAMPLE
    .\Deploy-Jboss.ps1 -servers "nvd-int-admin","nvd-int-service","nvd-int-web" -serviceName 
    "JBOSSEAP6" -schedTaskName "skip" -section "first"
    Stops the Windows service "JBOSSEAP6" on each server listed, but does not call the Windows 
    scheduled task to get the latest WAR file, nor does it Start the "JBOSSEAP6" service.
.EXAMPLE
    .\Deploy-Jboss.ps1 -servers "nvd-int-admin","nvd-int-service","nvd-int-web" -serviceName 
    "JBOSSEAP6" -section "second"
    Starts the Windows service "JBOSSEAP6" and monitors for ".deployed" and ".failed" files
.EXAMPLE
    .\Deploy-Jboss.ps1 -servers "nvd-int-admin","nvd-int-web" -serviceName "NONE" 
	-schedTaskName "Deploy 800-53 WAR File" -filterPrefix "800-53" 
    Calls the "Deploy 800-53 WAR File" Windows Scheduled task on NVD-INT-ADMIN and NVD-INT-WEB
	to deploy the latest 800-53 WAR files. Monitors to make sure the files deploy, but does NOT
	stop or start the JBoss Service.

#>

param(
    [array]$servers,
    [string]$serviceName,
    [string]$schedTaskName,
    [string]$section,
	[string]$filterPrefix,
	[string]$credFile,
	[string]$password
)
if(("x$servers" -eq "x") -OR ($servers.count -eq 0) -OR ("x$serviceName" -eq "x")){
	$errStr="The parameters 'servers' and 'serviceName' are required. ";
	$name=$MyInvocation.MyCommand.Name;
	$errStr=$errStr+"Please run 'Get-Help $name' for more information.";
	Throw $errStr;
}
$creds = ""
if(("x$credFile" -ne "x") -AND (Test-Path $credFile)){
	$creds = Import-CliXml $credFile
}
elseif("x$password" -ne "x"){
	$secPass = ConvertTo-SecureString $password -AsPlainText -Force
	$creds = New-Object System.Management.Automation.PSCredential ("sched_tasks", $secPass)
	
	try{
		Invoke-Command -Computer $servers -Credential $creds -UseSSL -ErrorAction Stop -ScriptBlock { Test-WSMan }
	}
	catch {
		Write-Host "Password is not correct. Deployment aborted."
		Write-Host "Error connecting to $servers using credentials: $_"
		Write-Host "Exiting."
		exit
	}
}
if("x$creds" -ne "x"){
	$wars = Invoke-Command -computerName $servers -scriptBlock { dir $env:JBOSS_HOME\standalone\deployments\*.war } -Credential $creds -UseSSL
}
else{
	$wars = Invoke-Command -computerName $servers -scriptBlock { dir $env:JBOSS_HOME\standalone\deployments\*.war }
}
$totalWarCount = $wars.Name.count

if(("x$section" -eq "x") -OR ($section.toLower() -eq "first")){
    $scriptBlock={
        param ($srvcName)
        $h=Get-Content env:computername
        if((Get-Service "$srvcName").Status -ne "Stopped"){
            Write-Host "Stopping Service: $h\$srvcName"
            NET STOP "$srvcName"
            $count=0
            While((Get-Service "$srvcName").Status -ne "Stopped"){
                Write-Host "$h\$srvcName Status:" ((Get-Service "$srvcName").Status)
                Sleep -Seconds 10
                $count++
                if($count -gt 10){
					if(((Get-Process | Where { $_.ProcessName -eq "prunsrv" }).count) -GT 0){
						Stop-Process -Name "prunsrv" -Force
					}
					if(((Get-Process | Where { $_.ProcessName -eq "java" }).count) -GT 0){
						Stop-Process -Name "java" -Force
					}
                }
            }
            Write-Host "Jboss Status on $h :" ((Get-Service "$srvcName").Status)
        }
        else{
            Write-Host "Service $h\$srvcName already stopped."
        }	
    }
	if($serviceName.toLower() -ne "none"){
		if("x$creds" -ne "x"){
			Invoke-Command -computerName $servers -scriptBlock $scriptBlock -ArgumentList "$serviceName" -Credential $creds -UseSSL
			Invoke-Command -computerName $servers -scriptBlock { dir $env:JBOSS_HOME\standalone\deployments } -Credential $creds -UseSSL
			Invoke-Command -ComputerName $servers -ScriptBlock { if(Test-Path "$env:JBOSS_HOME\standalone\deployments\*.war.*") { del $env:JBOSS_HOME\standalone\deployments\*.war.*} } -Credential $creds -UseSSL
			Invoke-Command -ComputerName $servers -ScriptBlock { if(Test-Path "$env:JBOSS_HOME\standalone\data") { del $env:JBOSS_HOME\standalone\data -Recurse } } -Credential $creds -UseSSL
			#Invoke-Command -ComputerName $servers -ScriptBlock { if(Test-Path "$env:JBOSS_HOME\standalone\log") { del $env:JBOSS_HOME\standalone\log -Recurse } } -Credential $creds -UseSSL
			Invoke-Command -ComputerName $servers -ScriptBlock { if(Test-Path "$env:JBOSS_HOME\standalone\tmp") { del $env:JBOSS_HOME\standalone\tmp -Recurse } } -Credential $creds -UseSSL
			Invoke-Command -computerName $servers -scriptBlock { dir $env:JBOSS_HOME\standalone\deployments } -Credential $creds -UseSSL
		}
		else{
			Invoke-Command -computerName $servers -scriptBlock $scriptBlock -ArgumentList "$serviceName"
			Invoke-Command -computerName $servers -scriptBlock { dir $env:JBOSS_HOME\standalone\deployments }
			Invoke-Command -ComputerName $servers -ScriptBlock { if(Test-Path "$env:JBOSS_HOME\standalone\deployments\*.war.*") { del $env:JBOSS_HOME\standalone\deployments\*.war.*} }
			Invoke-Command -ComputerName $servers -ScriptBlock { if(Test-Path "$env:JBOSS_HOME\standalone\data") { del $env:JBOSS_HOME\standalone\data -Recurse } }
			#Invoke-Command -ComputerName $servers -ScriptBlock { if(Test-Path "$env:JBOSS_HOME\standalone\log") { del $env:JBOSS_HOME\standalone\log -Recurse } }
			Invoke-Command -ComputerName $servers -ScriptBlock { if(Test-Path "$env:JBOSS_HOME\standalone\tmp") { del $env:JBOSS_HOME\standalone\tmp -Recurse } }
			Invoke-Command -computerName $servers -scriptBlock { dir $env:JBOSS_HOME\standalone\deployments }
		}
	}
	
    if(("x$schedTaskName" -ne "x") -AND ($schedTaskName.toLower() -ne "skip")){

        #Get the LastWriteTimes of the current WAR files
        $initial_LWTs=@{}
		$getLWTs_Block = {
            param($filter)
			$warFiles = Get-ChildItem -Path $env:JBOSS_HOME\standalone\deployments -Filter "$filter" 
			if($warFiles.count -GT 0){
				$warFiles | % { @{$_.name.trim()=$_.LastWriteTime} }
			}
			else{
				@{}
			}
		}
		if("x$creds" -ne "x"){
			$servers | % { $initial_LWTs += (Invoke-Command -computerName $_ -scriptBlock $getLWTs_Block -ArgumentList "$filterPrefix*.war" -Credential $creds -UseSSL )}
		}
		else{
			$servers | % { $initial_LWTs += (Invoke-Command -computerName $_ -scriptBlock $getLWTs_Block -ArgumentList "$filterPrefix*.war" )}
		}
        Write-Host "Initial:"
        $initial_LWTs.GetEnumerator()
        Write-Host
        $keys = $initial_LWTs.Keys
        #Call the scheduled task to update the WAR File
        $getWarBlock={
            param($taskName)
            Start-ScheduledTask -TaskName "$taskName"
        }
		if("x$creds" -ne "x"){
			Invoke-Command -computerName $servers -scriptBlock $getWarBlock -ArgumentList "$schedTaskName" -Credential $creds -UseSSL
		}
		else{
			Invoke-Command -computerName $servers -scriptBlock $getWarBlock -ArgumentList "$schedTaskName"
		}

        $allUpdated = $false
		$yesterday = (Get-Date).AddDays(-1)
        $updated_LWTs = @{}
        while(-NOT ($allUpdated)){
            Start-Sleep -seconds 5
            $updated_LWTs = @{}
			if("x$creds" -ne "x"){
				$servers | % { $updated_LWTs += (Invoke-Command -computerName $_ -scriptBlock $getLWTs_Block -ArgumentList "$filterPrefix*.war" -Credential $creds -UseSSL )}
			}
			else{
				$servers | % { $updated_LWTs += (Invoke-Command -computerName $_ -scriptBlock $getLWTs_Block -ArgumentList "$filterPrefix*.war" )}
			}
            $updated_LWTs.Keys | % { if(-NOT($keys -contains $_ )){$keys += $_ }}
			foreach($key in $keys){ 
                $initial = $initial_LWTs[$key]
                $updated = $updated_LWTs[$key]
                if(($updated -ne $NULL) -AND ($initial -ne $NULL) -AND ($initial -ge $updated)){
                    Write-Host "WAR File ($key) not updated yet: $updated"
                    $allUpdated = $false
                    Break
                }
                elseif($initial -eq $NULL){
					Write-Host "WAR file ($key) not found initially. This indicates it is the first time it has been deployed."
					if(($updated -ne $NULL) -AND ($yesterday -ge $updated)){
						Write-Host "New WAR File ($key) not updated yet: $updated"
						Break
					}
				}
                elseif($updated -eq $NULL){
                    Write-Host "WAR file ($key) has been deleted. This indicates a change in versions."
                }
                $allUpdated = $true
            }
        }
        Write-Host "Updated:"
        $updated_LWTs.GetEnumerator()

    }
    else{
        Write-Host "No Windows Scheduled Task name provided (schedTaskName param) - Skipped Deploy Step."
    }
}
$warCount = 0
while($warCount -lt $totalWarCount){
	if("x$creds" -ne "x"){
		$wars = Invoke-Command -computerName $servers -scriptBlock { dir $env:JBOSS_HOME\standalone\deployments\*.war } -Credential $creds -UseSSL
	}
	else{
		$wars = Invoke-Command -computerName $servers -scriptBlock { dir $env:JBOSS_HOME\standalone\deployments\*.war }
	}
    $warCount = $wars.Name.count
    Write-Host "warCount: $warCount"
}

if(("x$section" -eq "x") -OR ($section.toLower() -eq "second")){
    #Start the JBoss service
    
    $scriptBlock={
        param ($srvcName)
        $h=Get-Content env:computername
        if((Get-Service "$srvcName").Status -eq "Stopped"){
			Write-Host "Checking for updated JBoss Config Files."
			
            Write-Host "Starting Service: $h\$srvcName"
            NET START "$srvcName"
            Start-Sleep -seconds 5
            Write-Host "Jboss Status on $h :" ((Get-Service "$srvcName").Status)
        }
        else{
            Write-Host "Service $h\$srvcName is already running."
        }	
    }
	if($serviceName.toLower() -ne "none"){
		if("x$creds" -ne "x"){
			Invoke-Command -computerName $servers -scriptBlock $scriptBlock -ArgumentList "$serviceName" -Credential $creds -UseSSL
		}
		else{
			Invoke-Command -computerName $servers -scriptBlock $scriptBlock -ArgumentList "$serviceName"
		}
	}
	
    $failedCount = $deployedCount = 0

    while(($failedCount + $deployedCount) -lt $warCount){
        Write-Host "Waiting 5 seconds..."
        Start-Sleep -seconds 5
		if("x$creds" -ne "x"){
			$failedCount = (Invoke-Command -computerName $servers -scriptBlock { dir "$env:JBOSS_HOME\standalone\deployments\*.war.failed" } -Credential $creds -UseSSL).Name.count
			Write-Host "failedCount: $failedCount"
			$deployedCount = (Invoke-Command -computerName $servers -scriptBlock { dir "$env:JBOSS_HOME\standalone\deployments\*.war.deployed" } -Credential $creds -UseSSL).Name.count
			Write-Host "deployedCount: $deployedCount"
		}
		else{
			$failedCount = (Invoke-Command -computerName $servers -scriptBlock { dir "$env:JBOSS_HOME\standalone\deployments\*.war.failed" }).Name.count
			Write-Host "failedCount: $failedCount"
			$deployedCount = (Invoke-Command -computerName $servers -scriptBlock { dir "$env:JBOSS_HOME\standalone\deployments\*.war.deployed" }).Name.count
			Write-Host "deployedCount: $deployedCount"
		}	
    }
	
	#Delete each ".failed" file and re-check 
	if($failedCount -gt 0){
		$failedCount = $deployedCount = 0
		Write-Host "Removing all .failed files."
		if("x$creds" -ne "x"){
			Invoke-Command -computerName $servers -scriptBlock { Remove-Item -Path "$env:JBOSS_HOME\standalone\deployments\*.war.failed" -Force } -Credential $creds -UseSSL
		}
		else{
			Invoke-Command -computerName $servers -scriptBlock { Remove-Item -Path "$env:JBOSS_HOME\standalone\deployments\*.war.failed" -Force }
		}
	
		while(($failedCount + $deployedCount) -lt $warCount){
			Write-Host "Waiting 5 seconds..."
			Start-Sleep -seconds 5
			if("x$creds" -ne "x"){
				$failedList = (Invoke-Command -computerName $servers -scriptBlock { dir "$env:JBOSS_HOME\standalone\deployments\*.war.failed" } -Credential $creds -UseSSL).Name
				$failedCount = $failedList.count
				Write-Host "failedCount: $failedCount"
				$deployedCount = (Invoke-Command -computerName $servers -scriptBlock { dir "$env:JBOSS_HOME\standalone\deployments\*.war.deployed" } -Credential $creds -UseSSL).Name.count
				Write-Host "deployedCount: $deployedCount"
			}
			else{
				$failedList = (Invoke-Command -computerName $servers -scriptBlock { dir "$env:JBOSS_HOME\standalone\deployments\*.war.failed" }).Name
				$failedCount = $failedList.count
				Write-Host "failedCount: $failedCount"
				$deployedCount = (Invoke-Command -computerName $servers -scriptBlock { dir "$env:JBOSS_HOME\standalone\deployments\*.war.deployed" }).Name.count
				Write-Host "deployedCount: $deployedCount"
			}
		}
    }
	if("x$creds" -ne "x"){
		$undeployedCount = (Invoke-Command -computerName $servers -scriptBlock { dir "$env:JBOSS_HOME\standalone\deployments\*.war.undeployed" } -Credential $creds -UseSSL).Name.count
	}
	else{
		$undeployedCount = (Invoke-Command -computerName $servers -scriptBlock { dir "$env:JBOSS_HOME\standalone\deployments\*.war.undeployed" }).Name.count
	}
	if($undeployedCount -gt 0){
		Write-Host "Found undeployed file - deleting - Waiting 10 sec"
		if("x$creds" -ne "x"){
			Invoke-Command -computerName $servers -scriptBlock { Remove-Item -Path "$env:JBOSS_HOME\standalone\deployments\*.war.undeployed" -Force } -Credential $creds -UseSSL
		}
		else{
			Invoke-Command -computerName $servers -scriptBlock { Remove-Item -Path "$env:JBOSS_HOME\standalone\deployments\*.war.undeployed" -Force }
		}
		Start-Sleep -seconds 10
	}

    if($failedCount -gt 0){
        Write-Error "The following files failed to deploy"
		if("x$creds" -ne "x"){
			Invoke-Command -computerName $servers -scriptBlock { dir $env:JBOSS_HOME\standalone\deployments\*.war.failed} -Credential $creds -UseSSL
		}
		else{
			Invoke-Command -computerName $servers -scriptBlock { dir $env:JBOSS_HOME\standalone\deployments\*.war.failed}
		}
    }
    else{
        Write-Host "All WAR files deployed successfully"
		if("x$creds" -ne "x"){
			Invoke-Command -computerName $servers -scriptBlock { dir $env:JBOSS_HOME\standalone\deployments\*.war.*} -Credential $creds -UseSSL
		}
		else{
			Invoke-Command -computerName $servers -scriptBlock { dir $env:JBOSS_HOME\standalone\deployments\*.war.*}
		}
    }
		
}