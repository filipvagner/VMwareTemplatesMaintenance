###########################################################
# AUTHOR  : Filip Vagner
# EMAIL   : filip.vagner@hotmail.com
# DATE    : 08-08-2019
# COMMENT : This script maintains virtual machine template.
#           Desired template is converted to virtual machine, if all pre-requisities are met,
#           then operating system update is performed.
#           After all tasks are completed, virtual machine is converted back to tempalte
# FIX: Problem with UTC time vs. Daylight saving time
###########################################################

# Setting prefernce variables
$ErrorActionPreference = 'SilentlyContinue'
$WarningPreference  = 'SilentlyContinue'
$ConfirmPreference = 'None'

# Loading functions into memory
. $env:ProgramData\vmware-templates-maintenance\Write-MessageToLogFile.ps1 # Function "Write-MessageToLogFile" to write log entries to file

# Defining variables
$TemplateWin2k16Std = '<template name>'
$NewLogDateWin2k16Std = Get-Date -Format dd-MM-yyyy-HH-mm-ss
$vCenterServer = '<server name>'
$CheckCounter = 0
$AddHoursLocationVsUTC = 1

# New log file to record progress of template update
if (!(Test-Path -Path "$env:ProgramData\vmware-templates-maintenance\win2k16")) {
    New-Item -Path "$env:ProgramData\vmware-templates-maintenance\" -Name 'win2k16' -ItemType Directory
    New-Item -Path "$env:ProgramData\vmware-templates-maintenance\win2k16" -Name "$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt" -ItemType File
} else {
    New-Item -Path "$env:ProgramData\vmware-templates-maintenance\win2k16" -Name "$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt" -ItemType File
}

# >>>> Preparing virtual machine <<<<
# Connecting to vCenter
$UserNameToAccessVcenter = '<user name>@<domain name>'
$EncryptedPasswordToAccessVcenter = Get-Content -Path "$env:ProgramData\vmware-templates-maintenance\eid.txt" | ConvertTo-SecureString
$CredentialsToAccessVcenter = New-Object -TypeName System.Management.Automation.PSCredential($UserNameToAccessVcenter, $EncryptedPasswordToAccessVcenter)

Write-MessageToLogFile -LogMessage "INFORMATION - Script is connecting to vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
try {
    Connect-VIServer -Server $vCenterServer -Credential $CredentialsToAccessVcenter -ErrorAction Stop
    Write-MessageToLogFile -LogMessage "INFORMATION - Script successfully connected to vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
    Start-Sleep -Seconds 5
}
catch {
    Write-MessageToLogFile -LogMessage "ERROR - Script did not connect to vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
    Start-Sleep -Seconds 5
    Write-MessageToLogFile -LogMessage "ERROR - script has been terminated!" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
    exit
}

# Converting template to virtual machine
if (Get-Template -Name $TemplateWin2k16Std -ErrorAction SilentlyContinue) {
    Set-Template -Template $TemplateWin2k16Std -ToVM
    Write-MessageToLogFile -LogMessage "INFORMATION - Template $TemplateWin2k16Std converted to virtual machine" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
    Start-Sleep -Seconds 5
} elseif (Get-VM -Name $TemplateWin2k16Std -ErrorAction SilentlyContinue) {
    Get-VM -Name $TemplateWin2k16Std
    Write-MessageToLogFile -LogMessage "WARNING - Template $TemplateWin2k16Std already set as virtual machine" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
    Start-Sleep -Seconds 5
} else {
    Write-MessageToLogFile -LogMessage "ERROR - Template $TemplateWin2k16Std not found or other problem to convert template occured" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
    Start-Sleep -Seconds 5
    Write-MessageToLogFile -LogMessage "ERROR - script has been terminated!" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
    exit
}

# Powering on virtual machine
Get-VM -Name $TemplateWin2k16Std | Start-VM
Write-MessageToLogFile -LogMessage "INFORMATION - Virtual machine $TemplateWin2k16Std has been started" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
Start-Sleep -Seconds 30

# Checking overall status of virtual machine
Write-MessageToLogFile -LogMessage "INFORMATION - Checking overall virtual machine $TemplateWin2k16Std status" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
do {
    $TemplateWin2k16StdGuestState = $null
    $TemplateWin2k16StdVMToolsStatus = $null
    $TemplateWin2k16StdHeartBeatStatus = $null
    $TemplateWin2k16StdOverallStatus = $null
    
    Start-Sleep -Seconds 15

    $TemplateWin2k16StdGuestState = (Get-VM -Name $TemplateWin2k16Std | Get-View).Guest.GuestState
    Write-MessageToLogFile -LogMessage "INFORMATION - Virtual machine $TemplateWin2k16Std Guest state: $TemplateWin2k16StdGuestState" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
    $TemplateWin2k16StdVMToolsStatus = (Get-VM -Name $TemplateWin2k16Std | Get-View).Guest.ToolsStatus
    if ($TemplateWin2k16StdVMToolsStatus -like 'toolsOld') {
        Write-MessageToLogFile -LogMessage "WARNING - Virtual machine $TemplateWin2k16Std VMtools status: $TemplateWin2k16StdVMToolsStatus" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
        Start-Sleep -Seconds 5
        Update-Tools -VM $TemplateWin2k16Std
    } else {
        Write-MessageToLogFile -LogMessage "INFORMATION - Virtual machine $TemplateWin2k16Std VMtools status: $TemplateWin2k16StdVMToolsStatus" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
    }
    $TemplateWin2k16StdHeartBeatStatus = (Get-VM -Name $TemplateWin2k16Std | Get-View).GuestHeartbeatStatus
    Write-MessageToLogFile -LogMessage "INFORMATION - Virtual machine $TemplateWin2k16Std Heartbeat status: $TemplateWin2k16StdHeartBeatStatus" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
    $TemplateWin2k16StdOverallStatus = (Get-VM -Name $TemplateWin2k16Std | Get-View).OverallStatus
    Write-MessageToLogFile -LogMessage "INFORMATION - Virtual machine $TemplateWin2k16Std Overall status: $TemplateWin2k16StdOverallStatus" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"

    if ($CheckCounter -ge 1920) {
        # 1920 is value equal to 8 hours (Each check is performed in 15 seconds. 60 seconds/15 is 4. 4 multiple by 60 is 1 hour (240). 240 multiple by 8 is eight hours)
        Write-MessageToLogFile -LogMessage "ERROR - Check counter exceeded limit, virtual machine $TemplateWin2k16Std status did not meet conditions to be successfully updated" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
        Start-Sleep -Seconds 5
        Write-MessageToLogFile -LogMessage "INFORMATION - Powering off virtual machine $TemplateWin2k16Std" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
        Get-VM -Name $TemplateWin2k16Std | Stop-VM -Confirm:$false
        Write-MessageToLogFile -LogMessage "WARNING - Check virtual machine $TemplateWin2k16Std status" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
        Disconnect-VIServer -Server $vCenterServer -Confirm:$false
        Write-MessageToLogFile -LogMessage "INFORMATION - Script successfully disconnected from vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
        exit
    }
    $CheckCounter++
} until (($TemplateWin2k16StdGuestState -like 'running') -and ($TemplateWin2k16StdVMToolsStatus -like 'toolsOk') -and ($TemplateWin2k16StdHeartBeatStatus -like 'green') -and ($TemplateWin2k16StdOverallStatus -like 'green'))
Write-MessageToLogFile -LogMessage "INFORMATION - Status of virtual machine $TemplateWin2k16Std met all conditions to continue" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
Start-Sleep -Seconds 30

# >>>> Checking operating system <<<<
# Getting login and OS information
$UserNameToAccessTemplate = 'Administrator'
$EncryptedPasswordToAccessTemplate = Get-Content -Path "$env:ProgramData\vmware-templates-maintenance\mid.txt" | ConvertTo-SecureString
$CredentialsToAccessTemplate = New-Object -TypeName System.Management.Automation.PSCredential($UserNameToAccessTemplate, $EncryptedPasswordToAccessTemplate)
$TemplateWin2k16StdIPAddress = (Get-VMGuest -VM $TemplateWin2k16Std).IPAddress | Where-Object {$_.StartsWith("10")}
$TemplateWin2k16StdHostName = (Get-VMGuest -VM $TemplateWin2k16Std).HostName

# Checking if Windows operating system is ready
$CheckCounter = 0
Clear-Variable -Name TemplateWin2k16StdVMToolsStatus
Write-MessageToLogFile -LogMessage "INFORMATION - Checking status of operating system on $TemplateWin2k16Std , OS with name $TemplateWin2k16StdHostName and IP $TemplateWin2k16StdIPAddress" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
do {
    $TemplateWin2k16StdServiceServerStatus = $null
    $TemplateWin2k16StdAUOptions = $null
    $TemplateWin2k16StdVMToolsStatus = $null

    $TemplateWin2k16StdServiceServerStatus = Invoke-Command -ComputerName $TemplateWin2k16StdIPAddress -ScriptBlock {(Get-Service -Name LanmanServer).Status} -Credential $CredentialsToAccessTemplate
    $TemplateWin2k16StdAUOptions = Invoke-Command -ComputerName $TemplateWin2k16StdIPAddress -ScriptBlock {(Get-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\ -Name AUOptions).AUOptions} -Credential $CredentialsToAccessTemplate
    $TemplateWin2k16StdVMToolsStatus = (Get-VM -Name $TemplateWin2k16Std | Get-View).Guest.ToolsStatus

    Start-Sleep -Seconds 15

    if (Test-Connection -ComputerName $TemplateWin2k16StdIPAddress -Count 1) {
        Write-MessageToLogFile -LogMessage "INFORMATION - Virtual machine $TemplateWin2k16Std is connected to network" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"    
    } else {
        Write-MessageToLogFile -LogMessage "WARNING - Virtual machine $TemplateWin2k16Std is not connected to network" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"    
    }

    if ($TemplateWin2k16StdServiceServerStatus -like 'Running') {
        Write-MessageToLogFile -LogMessage "INFORMATION - Status of service Server: $TemplateWin2k16StdServiceServerStatus" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"    
    } else {
        Write-MessageToLogFile -LogMessage "WARNING - Status of service Server: $TemplateWin2k16StdServiceServerStatus" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
    }
        
    if ((Invoke-Command -ComputerName $TemplateWin2k16StdIPAddress -ScriptBlock {Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"} -Credential $CredentialsToAccessTemplate) -or (Invoke-Command -ComputerName $TemplateWin2k16StdIPAddress -ScriptBlock {Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting"} -Credential $CredentialsToAccessTemplate) -or (Invoke-Command -ComputerName $TemplateWin2k16StdIPAddress -ScriptBlock {Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"} -Credential $CredentialsToAccessTemplate) -or (Invoke-Command -ComputerName $TemplateWin2k16StdIPAddress -ScriptBlock {Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending"} -Credential $CredentialsToAccessTemplate)) {
        Write-MessageToLogFile -LogMessage "WARNING - Reboot pending in OS $TemplateWin2k16StdHostName" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
        Write-MessageToLogFile -LogMessage "INFORMATION - Rebooting virtual machine $TemplateWin2k16Std" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
        Get-VM -Name $TemplateWin2k16Std | Restart-VMGuest
        Start-Sleep -Seconds 15
    } else {
        Write-MessageToLogFile -LogMessage "INFORMATION - No reboot pending in OS $TemplateWin2k16StdHostName" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
    }

    if (!($TemplateWin2k16StdAUOptions -eq 4)) {
        Write-MessageToLogFile -LogMessage "WARNING - Windows Update in OS $TemplateWin2k16StdHostName is not set to Install updates automatically" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
        Write-MessageToLogFile -LogMessage "INFORMATION - Setting Windows Update in OS $TemplateWin2k16StdHostName to Install updates automatically" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
        Invoke-Command -ComputerName $TemplateWin2k16StdIPAddress -ScriptBlock {Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\ -Name AUOptions -Value 4} -Credential $CredentialsToAccessTemplate
        Start-Sleep -Seconds 5
        Write-MessageToLogFile -LogMessage "INFORMATION - Rebooting virtual machine $TemplateWin2k16Std" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
        Get-VM -Name $TemplateWin2k16Std | Restart-VMGuest
        Start-Sleep -Seconds 15
    } else {
        Write-MessageToLogFile -LogMessage "INFORMATION - Windows Updates are set in OS $TemplateWin2k16StdHostName to Install updates automatically" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
    }
    
    if ($CheckCounter -ge 1920) {
        # 1920 is value equal to 8 hours (Each check is performed in 15 seconds. 60 seconds/15 is 4. 4 multiple by 60 is 1 hour (240). 240 multiple by 8 is eight hours)
        Write-MessageToLogFile -LogMessage "ERROR - Check counter exceeded limit, virtual machine $TemplateWin2k16Std status did not meet conditions to be successfully updated" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
        Start-Sleep -Seconds 5
        Write-MessageToLogFile -LogMessage "INFORMATION - Powering off virtual machine $TemplateWin2k16Std" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
        Get-VM -Name $TemplateWin2k16Std | Stop-VM -Confirm:$false
        Write-MessageToLogFile -LogMessage "WARNING - Check virtual machine $TemplateWin2k16Std status" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
        Disconnect-VIServer -Server $vCenterServer -Confirm:$false
        Write-MessageToLogFile -LogMessage "INFORMATION - Script successfully disconnected from vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
        exit
    }
    $CheckCounter++
} until ((Test-Connection -ComputerName $TemplateWin2k16StdIPAddress -Count 5) -and ($TemplateWin2k16StdServiceServerStatus -like 'Running') -and ($TemplateWin2k16StdVMToolsStatus -like 'toolsOk') -and ($TemplateWin2k16StdAUOptions -eq 4))
Write-MessageToLogFile -LogMessage "INFORMATION - Status of operating system on $TemplateWin2k16Std , OS with name $TemplateWin2k16StdHostName met all conditions to start Windows update" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
Start-Sleep -Seconds 30

# >>>> Installing Windows updates <<<<
Write-MessageToLogFile -LogMessage "INFORMATION - Getting information about Windows Update status on $TemplateWin2k16Std , OS with name $TemplateWin2k16StdHostName and IP $TemplateWin2k16StdIPAddress" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"

# Checking for new updates
$CheckCounter = 0
$TemplateWin2k16StdMuLSSD = Invoke-Command -ComputerName $TemplateWin2k16StdIPAddress -ScriptBlock {(New-Object -ComObject "Microsoft.Update.AutoUpdate").Results.LastSearchSuccessDate} -Credential $CredentialsToAccessTemplate
$CurrentDateTimeStamp = Get-Date

Write-MessageToLogFile -LogMessage "INFORMATION - Last Windows update check $TemplateWin2k16StdMuLSSD (UTC Time)" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
if (($CurrentDateTimeStamp.AddMinutes(-15)) -gt ($TemplateWin2k16StdMuLSSD.AddHours($AddHoursLocationVsUTC))) { # Adding two hours to Last Detection time because it is in UTC time
    Write-MessageToLogFile -LogMessage "INFORMATION - Checking for new Windows updates" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
    Invoke-Command -ComputerName $TemplateWin2k16StdIPAddress -ScriptBlock {& C:\Windows\System32\UsoClient.exe StartScan} -Credential $CredentialsToAccessTemplate
    
    do {
        Clear-Variable -Name TemplateWin2k16StdMuLSSD
        
        $TemplateWin2k16StdMuLSSD = Invoke-Command -ComputerName $TemplateWin2k16StdIPAddress -ScriptBlock {(New-Object -ComObject "Microsoft.Update.AutoUpdate").Results.LastSearchSuccessDate} -Credential $CredentialsToAccessTemplate
        
        Start-Sleep -Seconds 15
        #TODO initiate {& C:\Windows\System32\UsoClient.exe StartScan} each 500 cycles
        if ($CheckCounter -ge 1920) {
            # 1920 is value equal to 8 hours (Each check is performed in 15 seconds. 60 seconds/15 is 4. 4 multiple by 60 is 1 hour (240). 240 multiple by 8 is eight hours)
            Write-MessageToLogFile -LogMessage "ERROR - Check counter exceeded limit, virtual machine $TemplateWin2k16Std status did not meet conditions to be successfully updated" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            Start-Sleep -Seconds 5
            Write-MessageToLogFile -LogMessage "INFORMATION - Powering off virtual machine $TemplateWin2k16Std" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            Get-VM -Name $TemplateWin2k16Std | Stop-VM -Confirm:$false
            Write-MessageToLogFile -LogMessage "WARNING - Check virtual machine $TemplateWin2k16Std status" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            Disconnect-VIServer -Server $vCenterServer -Confirm:$false
            Write-MessageToLogFile -LogMessage "INFORMATION - Script successfully disconnected from vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            exit
        }
        $CheckCounter++
    } while ($CurrentDateTimeStamp -gt ($TemplateWin2k16StdMuLSSD.AddHours($AddHoursLocationVsUTC)))
}
Write-MessageToLogFile -LogMessage "INFORMATION - Windows Update check finished" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
Start-Sleep -Seconds 30

# Checking if Windows Update are pending for installation
Write-MessageToLogFile -LogMessage "INFORMATION - Checking for Windows updates pending to install" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
$CheckCounter = 0
Clear-Variable -Name CurrentDateTimeStamp
$CurrentDateTimeStamp = Get-Date

if (((Invoke-Command -ComputerName $TemplateWin2k16StdIPAddress -ScriptBlock {((New-Object -ComObject Microsoft.Update.Searcher).Search("IsInstalled=0").Updates | Where-Object {$_.IsDownloaded -eq $True}).Count} -Credential $CredentialsToAccessTemplate) -gt 0) -or (((Invoke-Command -ComputerName $TemplateWin2k16StdIPAddress -ScriptBlock {((New-Object -ComObject Microsoft.Update.Searcher).Search("IsInstalled=0").Updates).Count} -Credential $CredentialsToAccessTemplate) -gt 0))) {
    Write-MessageToLogFile -LogMessage "INFORMATION - Installing Windows Updates" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
    Invoke-Command -ComputerName $TemplateWin2k16StdIPAddress -ScriptBlock {& C:\Windows\System32\UsoClient.exe StartInstall} -Credential $CredentialsToAccessTemplate

    do {
        $TemplateWin2k16StdMuLISD = $null

        $TemplateWin2k16StdMuLISD = Invoke-Command -ComputerName $TemplateWin2k16StdIPAddress -ScriptBlock {(New-Object -ComObject "Microsoft.Update.AutoUpdate").Results.LastInstallationSuccessDate} -Credential $CredentialsToAccessTemplate

        Start-Sleep -Seconds 15
        
        if ($CheckCounter -ge 1920) {
            # 1920 is value equal to 8 hours (Each check is performed in 15 seconds. 60 seconds/15 is 4. 4 multiple by 60 is 1 hour (240). 240 multiple by 8 is eight hours)
            Write-MessageToLogFile -LogMessage "ERROR - Check counter exceeded limit, virtual machine $TemplateWin2k16Std status did not meet conditions to be successfully updated" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            Start-Sleep -Seconds 5
            Write-MessageToLogFile -LogMessage "INFORMATION - Powering off virtual machine $TemplateWin2k16Std" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            Get-VM -Name $TemplateWin2k16Std | Stop-VM -Confirm:$false
            Write-MessageToLogFile -LogMessage "WARNING - Check virtual machine $TemplateWin2k16Std status" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            Disconnect-VIServer -Server $vCenterServer -Confirm:$false
            Write-MessageToLogFile -LogMessage "INFORMATION - Script successfully disconnected from vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            exit
        }
        $CheckCounter++
    } while ($CurrentDateTimeStamp -gt ($TemplateWin2k16StdMuLISD.AddHours($AddHoursLocationVsUTC)))

    Write-MessageToLogFile -LogMessage "INFORMATION - Windows updates last successfful installation time $TemplateWin2k16StdMuLISD (UTC Time)" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
} else {
    Write-MessageToLogFile -LogMessage "INFORMATION - No Windows updates pending for installation" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
}

# Chekking if Windows update finished and rebooting server
$CheckCounter = 0

if ((Invoke-Command -ComputerName $TemplateWin2k16StdIPAddress -ScriptBlock {Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"} -Credential $CredentialsToAccessTemplate) -or (Invoke-Command -ComputerName $TemplateWin2k16StdIPAddress -ScriptBlock {Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting"} -Credential $CredentialsToAccessTemplate) -or (Invoke-Command -ComputerName $TemplateWin2k16StdIPAddress -ScriptBlock {Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"} -Credential $CredentialsToAccessTemplate) -or (Invoke-Command -ComputerName $TemplateWin2k16StdIPAddress -ScriptBlock {Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending"} -Credential $CredentialsToAccessTemplate)) {
    Write-MessageToLogFile -LogMessage "INFORMATION - Windows updates has been installed on server $TemplateWin2k16Std, OS with name $TemplateWin2k16StdHostName" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
    Get-VM -Name $TemplateWin2k16Std | Restart-VMGuest -Confirm:$false

    Start-Sleep -Seconds 30

    do {
        Write-MessageToLogFile -LogMessage "INFORMATION - Reboot in progress" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"

        $TemplateWin2k16StdGuestState = $null
        $TemplateWin2k16StdVMToolsStatus = $null
        $TemplateWin2k16StdHeartBeatStatus = $null
        $TemplateWin2k16StdOverallStatus = $null
        
        Start-Sleep -Seconds 15
    
        $TemplateWin2k16StdGuestState = (Get-VM -Name $TemplateWin2k16Std | Get-View).Guest.GuestState
        Write-MessageToLogFile -LogMessage "INFORMATION - Virtual machine $TemplateWin2k16Std Guest state: $TemplateWin2k16StdGuestState" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
        $TemplateWin2k16StdVMToolsStatus = (Get-VM -Name $TemplateWin2k16Std | Get-View).Guest.ToolsStatus
        if ($TemplateWin2k16StdVMToolsStatus -like 'toolsOld') {
            Write-MessageToLogFile -LogMessage "WARNING - Virtual machine $TemplateWin2k16Std VMtools status: $TemplateWin2k16StdVMToolsStatus" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            Start-Sleep -Seconds 5
            Update-Tools -VM $TemplateWin2k16Std
        } else {
            Write-MessageToLogFile -LogMessage "INFORMATION - Virtual machine $TemplateWin2k16Std VMtools status: $TemplateWin2k16StdVMToolsStatus" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
        }
        $TemplateWin2k16StdHeartBeatStatus = (Get-VM -Name $TemplateWin2k16Std | Get-View).GuestHeartbeatStatus
        Write-MessageToLogFile -LogMessage "INFORMATION - Virtual machine $TemplateWin2k16Std Heartbeat status: $TemplateWin2k16StdHeartBeatStatus" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
        $TemplateWin2k16StdOverallStatus = (Get-VM -Name $TemplateWin2k16Std | Get-View).OverallStatus
        Write-MessageToLogFile -LogMessage "INFORMATION - Virtual machine $TemplateWin2k16Std Overall status: $TemplateWin2k16StdOverallStatus" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
        
        if ($CheckCounter -ge 1920) {
            # 1920 is value equal to 8 hours (Each check is performed in 15 seconds. 60 seconds/15 is 4. 4 multiple by 60 is 1 hour (240). 240 multiple by 8 is eight hours)
            Write-MessageToLogFile -LogMessage "ERROR - Check counter exceeded limit, virtual machine $TemplateWin2k16Std status did not meet conditions to be successfully updated" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            Start-Sleep -Seconds 5
            Write-MessageToLogFile -LogMessage "INFORMATION - Powering off virtual machine $TemplateWin2k16Std" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            Get-VM -Name $TemplateWin2k16Std | Stop-VM -Confirm:$false
            Write-MessageToLogFile -LogMessage "WARNING - Check virtual machine $TemplateWin2k16Std status" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            Disconnect-VIServer -Server $vCenterServer -Confirm:$false
            Write-MessageToLogFile -LogMessage "INFORMATION - Script successfully disconnected from vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            exit
        }
        $CheckCounter++
    } while (($TemplateWin2k16StdGuestState -like 'running') -and ($TemplateWin2k16StdVMToolsStatus -like 'toolsOk') -and ($TemplateWin2k16StdHeartBeatStatus -like 'green') -and ($TemplateWin2k16StdOverallStatus -like 'green'))

    do {
        Write-MessageToLogFile -LogMessage "INFORMATION - Reboot in progress" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"

        $TemplateWin2k16StdGuestState = $null
        $TemplateWin2k16StdVMToolsStatus = $null
        $TemplateWin2k16StdHeartBeatStatus = $null
        $TemplateWin2k16StdOverallStatus = $null
        
        Start-Sleep -Seconds 15
    
        $TemplateWin2k16StdGuestState = (Get-VM -Name $TemplateWin2k16Std | Get-View).Guest.GuestState
        Write-MessageToLogFile -LogMessage "INFORMATION - Virtual machine $TemplateWin2k16Std Guest state: $TemplateWin2k16StdGuestState" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
        $TemplateWin2k16StdVMToolsStatus = (Get-VM -Name $TemplateWin2k16Std | Get-View).Guest.ToolsStatus
        if ($TemplateWin2k16StdVMToolsStatus -like 'toolsOld') {
            Write-MessageToLogFile -LogMessage "WARNING - Virtual machine $TemplateWin2k16Std VMtools status: $TemplateWin2k16StdVMToolsStatus" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            Start-Sleep -Seconds 5
            Update-Tools -VM $TemplateWin2k16Std
        } else {
            Write-MessageToLogFile -LogMessage "INFORMATION - Virtual machine $TemplateWin2k16Std VMtools status: $TemplateWin2k16StdVMToolsStatus" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
        }
        $TemplateWin2k16StdHeartBeatStatus = (Get-VM -Name $TemplateWin2k16Std | Get-View).GuestHeartbeatStatus
        Write-MessageToLogFile -LogMessage "INFORMATION - Virtual machine $TemplateWin2k16Std Heartbeat status: $TemplateWin2k16StdHeartBeatStatus" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
        $TemplateWin2k16StdOverallStatus = (Get-VM -Name $TemplateWin2k16Std | Get-View).OverallStatus
        Write-MessageToLogFile -LogMessage "INFORMATION - Virtual machine $TemplateWin2k16Std Overall status: $TemplateWin2k16StdOverallStatus" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
        
        if ($CheckCounter -ge 1920) {
            # 1920 is value equal to 8 hours (Each check is performed in 15 seconds. 60 seconds/15 is 4. 4 multiple by 60 is 1 hour (240). 240 multiple by 8 is eight hours)
            Write-MessageToLogFile -LogMessage "ERROR - Check counter exceeded limit, virtual machine $TemplateWin2k16Std status did not meet conditions to be successfully updated" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            Start-Sleep -Seconds 5
            Write-MessageToLogFile -LogMessage "INFORMATION - Powering off virtual machine $TemplateWin2k16Std" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            Get-VM -Name $TemplateWin2k16Std | Stop-VM -Confirm:$false
            Write-MessageToLogFile -LogMessage "WARNING - Check virtual machine $TemplateWin2k16Std status" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            Disconnect-VIServer -Server $vCenterServer -Confirm:$false
            Write-MessageToLogFile -LogMessage "INFORMATION - Script successfully disconnected from vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            exit
        }
        $CheckCounter++
    } until (($TemplateWin2k16StdGuestState -like 'running') -and ($TemplateWin2k16StdVMToolsStatus -like 'toolsOk') -and ($TemplateWin2k16StdHeartBeatStatus -like 'green') -and ($TemplateWin2k16StdOverallStatus -like 'green'))

    Write-MessageToLogFile -LogMessage "INFORMATION - Server rebooted" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
    Write-MessageToLogFile -LogMessage "INFORMATION - Shutting down server $TemplateWin2k16Std, OS with name $TemplateWin2k16StdHostName" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
    Get-VM -Name $TemplateWin2k16Std | Shutdown-VMGuest -Confirm:$false

    Start-Sleep -Seconds 30

    do {
        $TemplateWin2k16StdPowerState = $null
        
        Start-Sleep -Seconds 15
        $TemplateWin2k16StdPowerState = (Get-VM -Name $TemplateWin2k16Std).PowerState
        
        if ($CheckCounter -ge 1920) {
            # 1920 is value equal to 8 hours (Each check is performed in 15 seconds. 60 seconds/15 is 4. 4 multiple by 60 is 1 hour (240). 240 multiple by 8 is eight hours)
            Write-MessageToLogFile -LogMessage "ERROR - Check counter exceeded limit, virtual machine $TemplateWin2k16Std status did not meet conditions to be successfully updated" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            Start-Sleep -Seconds 5
            Write-MessageToLogFile -LogMessage "INFORMATION - Powering off virtual machine $TemplateWin2k16Std" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            Get-VM -Name $TemplateWin2k16Std | Stop-VM -Confirm:$false
            Write-MessageToLogFile -LogMessage "WARNING - Check virtual machine $TemplateWin2k16Std status" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            Disconnect-VIServer -Server $vCenterServer -Confirm:$false
            Write-MessageToLogFile -LogMessage "INFORMATION - Script successfully disconnected from vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            exit
        }
        $CheckCounter++
    } until ($TemplateWin2k16StdPowerState -like 'PoweredOff')

    $TemplateWin2k16StdVMNotes = Get-VM -Name $TemplateWin2k16Std | Select-Object -ExpandProperty Notes
    [int]$LastIndexOfColon = $TemplateWin2k16StdVMNotes.LastIndexOf(":")+1
    $TemplateWin2k16StdVMNotes = $TemplateWin2k16StdVMNotes.Remove($LastIndexOfColon)
    $TemplateWin2k16StdVMNotesLastUpdateDate = Get-Date -Format dd-MM-yyyy
    $TemplateWin2k16StdVMNotes = $TemplateWin2k16StdVMNotes.Insert($LastIndexOfColon," $TemplateWin2k16StdVMNotesLastUpdateDate")
    Set-VM -VM $TemplateWin2k16Std -Notes $TemplateWin2k16StdVMNotes -Confirm:$false

    Write-MessageToLogFile -LogMessage "INFORMATION - Converting virtual $TemplateWin2k16Std machine into template" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
    Get-VM -Name $TemplateWin2k16Std | Set-VM -ToTemplate -Confirm:$false

} else {
    Write-MessageToLogFile -LogMessage "INFORMATION - Shutting down server $TemplateWin2k16Std, OS with name $TemplateWin2k16StdHostName" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
    Get-VM -Name $TemplateWin2k16Std | Shutdown-VMGuest -Confirm:$false

    Start-Sleep -Seconds 30
    
    do {
        $TemplateWin2k16StdPowerState = $null
        
        Start-Sleep -Seconds 15
        $TemplateWin2k16StdPowerState = (Get-VM -Name $TemplateWin2k16Std).PowerState
        
        if ($CheckCounter -ge 1920) {
            # 1920 is value equal to 8 hours (Each check is performed in 15 seconds. 60 seconds/15 is 4. 4 multiple by 60 is 1 hour (240). 240 multiple by 8 is eight hours)
            Write-MessageToLogFile -LogMessage "ERROR - Check counter exceeded limit, virtual machine $TemplateWin2k16Std status did not meet conditions to be successfully updated" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            Start-Sleep -Seconds 5
            Write-MessageToLogFile -LogMessage "INFORMATION - Powering off virtual machine $TemplateWin2k16Std" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            Get-VM -Name $TemplateWin2k16Std | Stop-VM -Confirm:$false
            Write-MessageToLogFile -LogMessage "WARNING - Check virtual machine $TemplateWin2k16Std status" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            Disconnect-VIServer -Server $vCenterServer -Confirm:$false
            Write-MessageToLogFile -LogMessage "INFORMATION - Script successfully disconnected from vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
            exit
        }
        $CheckCounter++
    } until ($TemplateWin2k16StdPowerState -like 'PoweredOff')
    
    # Updating VM notes
    $TemplateWin2k16StdVMNotes = Get-VM -Name $TemplateWin2k16Std | Select-Object -ExpandProperty Notes
    [int]$LastIndexOfColon = $TemplateWin2k16StdVMNotes.LastIndexOf(":")+1
    $TemplateWin2k16StdVMNotes = $TemplateWin2k16StdVMNotes.Remove($LastIndexOfColon)
    $TemplateWin2k16StdVMNotesLastUpdateDate = Get-Date -Format dd-MM-yyyy
    $TemplateWin2k16StdVMNotes = $TemplateWin2k16StdVMNotes.Insert($LastIndexOfColon," $TemplateWin2k16StdVMNotesLastUpdateDate")
    Set-VM -VM $TemplateWin2k16Std -Notes $TemplateWin2k16StdVMNotes -Confirm:$false

    Write-MessageToLogFile -LogMessage "INFORMATION - Converting virtual $TemplateWin2k16Std machine into template" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"
    Get-VM -Name $TemplateWin2k16Std | Set-VM -ToTemplate -Confirm:$false
}

Write-MessageToLogFile -LogMessage "INFORMATION - Script has completed all steps" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"

Disconnect-VIServer -Server $vCenterServer -Confirm:$false
Write-MessageToLogFile -LogMessage "INFORMATION - Script successfully disconnected from vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k16\$TemplateWin2k16Std-$NewLogDateWin2k16Std.txt"

Get-ChildItem -Path "$env:ProgramData\vmware-templates-maintenance\" -Filter "ops_run_*.txt" | Remove-Item -Confirm:$false