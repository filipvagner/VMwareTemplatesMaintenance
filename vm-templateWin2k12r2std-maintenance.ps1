###########################################################
# AUTHOR  : Filip Vagner
# EMAIL   : filip.vagner@hotmail.com
# DATE    : 30-05-2019
# COMMENT : This script maintains virtual machine template specified.
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
$TemplateWin2k12r2Std = '<template name>'
$NewLogDateWin2k12r2Std = Get-Date -Format dd-MM-yyyy-HH-mm-ss
$vCenterServer = '<server name>'
$CheckCounter = 0
$AddHoursLocationVsUTC = 1

# New log file to record progress of template update
if (!(Test-Path -Path "$env:ProgramData\vmware-templates-maintenance\win2k12")) {
    New-Item -Path "$env:ProgramData\vmware-templates-maintenance\" -Name 'win2k12' -ItemType Directory
    New-Item -Path "$env:ProgramData\vmware-templates-maintenance\win2k12" -Name "$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt" -ItemType File
} else {
    New-Item -Path "$env:ProgramData\vmware-templates-maintenance" -Name "$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt" -ItemType File
}

# >>>> Preparing virtual machine <<<<
# Connecting to vCenter
$UserNameToAccessVcenter = '<user name>@<domain name>'
$EncryptedPasswordToAccessVcenter = Get-Content -Path "$env:ProgramData\vmware-templates-maintenance\eid.txt" | ConvertTo-SecureString
$CredentialsToAccessVcenter = New-Object -TypeName System.Management.Automation.PSCredential($UserNameToAccessVcenter, $EncryptedPasswordToAccessVcenter)

try {
    Write-MessageToLogFile -LogMessage "INFORMATION - Script is connecting to vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    Connect-VIServer -Server $vCenterServer -Credential $CredentialsToAccessVcenter -ErrorAction Stop
    Write-MessageToLogFile -LogMessage "INFORMATION - Script successfully connected to vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    Start-Sleep -Seconds 5
}
catch {
    Write-MessageToLogFile -LogMessage "ERROR - Script did not connect to vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    Start-Sleep -Seconds 5
    Write-MessageToLogFile -LogMessage "ERROR - script has been terminated!" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    exit
}

# Converting template to virtual machine
if (Get-Template -Name $TemplateWin2k12r2Std -ErrorAction SilentlyContinue) {
    Set-Template -Template $TemplateWin2k12r2Std -ToVM
    Write-MessageToLogFile -LogMessage "INFORMATION - Template $TemplateWin2k12r2Std converted to virtual machine" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    Start-Sleep -Seconds 5
} elseif (Get-VM -Name $TemplateWin2k12r2Std -ErrorAction SilentlyContinue) {
    Get-VM -Name $TemplateWin2k12r2Std
    Write-MessageToLogFile -LogMessage "WARNING - Template $TemplateWin2k12r2Std already set as virtual machine" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    Start-Sleep -Seconds 5
} else {
    Write-MessageToLogFile -LogMessage "ERROR - Template $TemplateWin2k12r2Std not found or other problem to convert template occured" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    Start-Sleep -Seconds 5
    Write-MessageToLogFile -LogMessage "ERROR - script has been terminated!" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    exit
}

# Powering on virtual machine
Get-VM -Name $TemplateWin2k12r2Std | Start-VM
Write-MessageToLogFile -LogMessage "INFORMATION - Virtual machine $TemplateWin2k12r2Std has been started" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
Start-Sleep -Seconds 30

# Checking overall status of virtual machine
Write-MessageToLogFile -LogMessage "INFORMATION - Checking overall virtual machine $TemplateWin2k12r2Std status" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"

do {
    $TemplateWin2k12r2StdGuestState = $null
    $TemplateWin2k12r2StdVMToolsStatus = $null
    $TemplateWin2k12r2StdHeartBeatStatus = $null
    $TemplateWin2k12r2StdOverallStatus = $null
    
    Start-Sleep -Seconds 15

    $TemplateWin2k12r2StdGuestState = (Get-VM -Name $TemplateWin2k12r2Std | Get-View).Guest.GuestState
    Write-MessageToLogFile -LogMessage "INFORMATION - Virtual machine $TemplateWin2k12r2Std Guest state: $TemplateWin2k12r2StdGuestState" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    $TemplateWin2k12r2StdVMToolsStatus = (Get-VM -Name $TemplateWin2k12r2Std | Get-View).Guest.ToolsStatus
    if ($TemplateWin2k12r2StdVMToolsStatus -like 'toolsOld') {
        Write-MessageToLogFile -LogMessage "WARNING - Virtual machine $TemplateWin2k12r2Std VMtools status: $TemplateWin2k12r2StdVMToolsStatus" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
        Write-MessageToLogFile -LogMessage "INFORMATION - Upgrading VMtools" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
        Start-Sleep -Seconds 5
        Update-Tools -VM $TemplateWin2k12r2Std
    } else {
        Write-MessageToLogFile -LogMessage "INFORMATION - Virtual machine $TemplateWin2k12r2Std VMtools status: $TemplateWin2k12r2StdVMToolsStatus" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    }
    $TemplateWin2k12r2StdHeartBeatStatus = (Get-VM -Name $TemplateWin2k12r2Std | Get-View).GuestHeartbeatStatus
    Write-MessageToLogFile -LogMessage "INFORMATION - Virtual machine $TemplateWin2k12r2Std Heartbeat status: $TemplateWin2k12r2StdHeartBeatStatus" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    $TemplateWin2k12r2StdOverallStatus = (Get-VM -Name $TemplateWin2k12r2Std | Get-View).OverallStatus
    Write-MessageToLogFile -LogMessage "INFORMATION - Virtual machine $TemplateWin2k12r2Std Overall status: $TemplateWin2k12r2StdOverallStatus" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    
    if ($CheckCounter -ge 1920) {
        # 1920 is value equal to 8 hours (Each check is performed in 15 seconds. 60 seconds/15 is 4. 4 multiple by 60 is 1 hour (240). 240 multiple by 8 is eight hours)
        Write-MessageToLogFile -LogMessage "ERROR - Check counter exceeded limit, virtual machine $TemplateWin2k12r2Std status did not meet conditions to be successfully updated" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
        Start-Sleep -Seconds 5
        Write-MessageToLogFile -LogMessage "INFORMATION - Powering off virtual machine $TemplateWin2k12r2Std" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
        Get-VM -Name $TemplateWin2k12r2Std | Stop-VM -Confirm:$false
        Write-MessageToLogFile -LogMessage "WARNING - Check virtual machine $TemplateWin2k12r2Std status" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
        Disconnect-VIServer -Server $vCenterServer -Confirm:$false
        Write-MessageToLogFile -LogMessage "INFORMATION - Script successfully disconnected from vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
        exit
    }
    $CheckCounter++
} until (($TemplateWin2k12r2StdGuestState -like 'running') -and ($TemplateWin2k12r2StdVMToolsStatus -like 'toolsOk') -and ($TemplateWin2k12r2StdHeartBeatStatus -like 'green') -and ($TemplateWin2k12r2StdOverallStatus -like 'green'))

Write-MessageToLogFile -LogMessage "INFORMATION - Status of virtual machine $TemplateWin2k12r2Std met all conditions to continue" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
Start-Sleep -Seconds 30

# >>>> Checking operating system <<<<
# Getting login and OS information
$UserNameToAccessTemplate = 'Administrator'
$EncryptedPasswordToAccessTemplate = Get-Content -Path "$env:ProgramData\vmware-templates-maintenance\mid.txt" | ConvertTo-SecureString
$CredentialsToAccessTemplate = New-Object -TypeName System.Management.Automation.PSCredential($UserNameToAccessTemplate, $EncryptedPasswordToAccessTemplate)
$TemplateWin2k12r2StdIPAddress = (Get-VMGuest -VM $TemplateWin2k12r2Std).IPAddress[0]
$TemplateWin2k12r2StdHostName = (Get-VMGuest -VM $TemplateWin2k12r2Std).HostName

# Checking if Windows operating system is ready
$CheckCounter = 0
Clear-Variable -Name TemplateWin2k12r2StdVMToolsStatus
Write-MessageToLogFile -LogMessage "INFORMATION - Checking status of operating system on $TemplateWin2k12r2Std , OS with name $TemplateWin2k12r2StdHostName and IP $TemplateWin2k12r2StdIPAddress" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"

do {
    $TemplateWin2k12r2StdServiceServerStatus = $null
    $TemplateWin2k12r2StdAUOptions = $null
    $TemplateWin2k12r2StdVMToolsStatus = $null

    Start-Sleep -Seconds 15

    $TemplateWin2k12r2StdServiceServerStatus = Invoke-Command -ComputerName $TemplateWin2k12r2StdIPAddress -ScriptBlock {(Get-Service -Name LanmanServer).Status} -Credential $CredentialsToAccessTemplate
    $TemplateWin2k12r2StdAUOptions = Invoke-Command -ComputerName $TemplateWin2k12r2StdIPAddress -ScriptBlock {(Get-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\ -Name AUOptions).AUOptions} -Credential $CredentialsToAccessTemplate
    $TemplateWin2k12r2StdVMToolsStatus = (Get-VM -Name $TemplateWin2k12r2Std | Get-View).Guest.ToolsStatus

    if (Test-Connection -ComputerName $TemplateWin2k12r2StdIPAddress -Count 1) {
        Write-MessageToLogFile -LogMessage "INFORMATION - Virtual machine $TemplateWin2k12r2Std is connected to network" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"    
    } else {
        Write-MessageToLogFile -LogMessage "WARNING - Virtual machine $TemplateWin2k12r2Std is not connected to network" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"    
    }
    
    if ($TemplateWin2k12r2StdServiceServerStatus -like 'Running') {
        Write-MessageToLogFile -LogMessage "INFORMATION - Status of service Server: $TemplateWin2k12r2StdServiceServerStatus" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"    
    } else {
        Write-MessageToLogFile -LogMessage "WARNING - Status of service Server: $TemplateWin2k12r2StdServiceServerStatus" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    }
        
    if ((Invoke-Command -ComputerName $TemplateWin2k12r2StdIPAddress -ScriptBlock {Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"} -Credential $CredentialsToAccessTemplate) -or (Invoke-Command -ComputerName $TemplateWin2k12r2StdIPAddress -ScriptBlock {Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting"} -Credential $CredentialsToAccessTemplate) -or (Invoke-Command -ComputerName $TemplateWin2k12r2StdIPAddress -ScriptBlock {Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"} -Credential $CredentialsToAccessTemplate) -or (Invoke-Command -ComputerName $TemplateWin2k12r2StdIPAddress -ScriptBlock {Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending"} -Credential $CredentialsToAccessTemplate)) {
        Write-MessageToLogFile -LogMessage "WARNING - Reboot pending in OS $TemplateWin2k12r2StdHostName" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
        Write-MessageToLogFile -LogMessage "INFORMATION - Rebooting virtual machine $TemplateWin2k12r2Std" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
        Get-VM -Name $TemplateWin2k12r2Std | Restart-VMGuest -Confirm:$false
        Start-Sleep -Seconds 30
    } else {
        Write-MessageToLogFile -LogMessage "INFORMATION - No reboot pending in OS $TemplateWin2k12r2StdHostName" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    }

    if (!($TemplateWin2k12r2StdAUOptions -eq 4)) {
        Write-MessageToLogFile -LogMessage "WARNING - Windows Update in OS $TemplateWin2k12r2StdHostName is not set to Install updates automatically" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
        Write-MessageToLogFile -LogMessage "INFORMATION - Setting Windows Update in OS $TemplateWin2k12r2StdHostName to Install updates automatically" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
        Invoke-Command -ComputerName $TemplateWin2k12r2StdIPAddress -ScriptBlock {Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\ -Name AUOptions -Value 4} -Credential $CredentialsToAccessTemplate
        Start-Sleep -Seconds 5
        Write-MessageToLogFile -LogMessage "INFORMATION - Rebooting virtual machine $TemplateWin2k12r2Std" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
        Get-VM -Name $TemplateWin2k12r2Std | Restart-VMGuest -Confirm:$false
        Start-Sleep -Seconds 30
    } else {
        Write-MessageToLogFile -LogMessage "INFORMATION - Windows Updates are set in OS $TemplateWin2k12r2StdHostName to Install updates automatically" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    }
    
    if ($CheckCounter -ge 1920) {
        # 1920 is value equal to 8 hours (Each check is performed in 15 seconds. 60 seconds/15 is 4. 4 multiple by 60 is 1 hour (240). 240 multiple by 8 is eight hours)
        Write-MessageToLogFile -LogMessage "ERROR - Check counter exceeded limit, virtual machine $TemplateWin2k12r2Std status did not meet conditions to be successfully updated" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
        Start-Sleep -Seconds 5
        Write-MessageToLogFile -LogMessage "INFORMATION - Powering off virtual machine $TemplateWin2k12r2Std" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
        Get-VM -Name $TemplateWin2k12r2Std | Stop-VM -Confirm:$false
        Write-MessageToLogFile -LogMessage "WARNING - Check virtual machine $TemplateWin2k12r2Std status" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
        Disconnect-VIServer -Server $vCenterServer -Confirm:$false
        Write-MessageToLogFile -LogMessage "INFORMATION - Script successfully disconnected from vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
        exit
    }
    $CheckCounter++
} until ((Test-Connection -ComputerName $TemplateWin2k12r2StdIPAddress -Count 5) -and ($TemplateWin2k12r2StdServiceServerStatus -like 'Running') -and ($TemplateWin2k12r2StdVMToolsStatus -like 'toolsOk') -and ($TemplateWin2k12r2StdAUOptions -eq 4))

Write-MessageToLogFile -LogMessage "INFORMATION - Status of operating system on $TemplateWin2k12r2Std , OS with name $TemplateWin2k12r2StdHostName met all conditions to start Windows update" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
Start-Sleep -Seconds 30

# >>>> Installing Windows updates <<<<
Write-MessageToLogFile -LogMessage "INFORMATION - Getting information about Windows Update status on $TemplateWin2k12r2Std , OS with name $TemplateWin2k12r2StdHostName and IP $TemplateWin2k12r2StdIPAddress" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"

# Checking for new updates
$CheckCounter = 0
$TemplateWin2k12r2StdRegLDT = Invoke-Command -ComputerName $TemplateWin2k12r2StdIPAddress -ScriptBlock {Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Detect' -Name LastSuccessTime} -Credential $CredentialsToAccessTemplate
$CultureInfo = [Globalization.CultureInfo]::InvariantCulture
$TemplateWin2k12r2StdRegLDTasDate = [DateTime]::ParseExact($TemplateWin2k12r2StdRegLDT, 'yyyy-MM-dd HH:mm:ss', $CultureInfo)
$CurrentDateTimeStamp = Get-Date

Write-MessageToLogFile -LogMessage "INFORMATION - Last Windows update check $TemplateWin2k12r2StdRegLDT (UTC Time)" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
if (($CurrentDateTimeStamp.AddMinutes(-15)) -gt ($TemplateWin2k12r2StdRegLDTasDate.AddHours($AddHoursLocationVsUTC))) { # Adding two hours to Last Detection time because it is in UTC time
    Write-MessageToLogFile -LogMessage "INFORMATION - Checking for new Windows updates" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    Invoke-Command -ComputerName $TemplateWin2k12r2StdIPAddress -ScriptBlock {& C:\Windows\System32\wuauclt.exe /DetectNow} -Credential $CredentialsToAccessTemplate
    
    do {
        Clear-Variable -Name TemplateWin2k12r2StdRegLDT
        Clear-Variable -Name TemplateWin2k12r2StdRegLDTasDate
        
        Start-Sleep -Seconds 15

        $TemplateWin2k12r2StdRegLDT = Invoke-Command -ComputerName $TemplateWin2k12r2StdIPAddress -ScriptBlock {Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Detect' -Name LastSuccessTime} -Credential $CredentialsToAccessTemplate
        $TemplateWin2k12r2StdRegLDTasDate = [DateTime]::ParseExact($TemplateWin2k12r2StdRegLDT, 'yyyy-MM-dd HH:mm:ss', $CultureInfo)

        if ($CheckCounter -ge 1920) {
            # 1920 is value equal to 8 hours (Each check is performed in 15 seconds. 60 seconds/15 is 4. 4 multiple by 60 is 1 hour (240). 240 multiple by 8 is eight hours)
            Write-MessageToLogFile -LogMessage "ERROR - Check counter exceeded limit, virtual machine $TemplateWin2k12r2Std status did not meet conditions to be successfully updated" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            Start-Sleep -Seconds 5
            Write-MessageToLogFile -LogMessage "INFORMATION - Powering off virtual machine $TemplateWin2k12r2Std" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            Get-VM -Name $TemplateWin2k12r2Std | Stop-VM -Confirm:$false
            Write-MessageToLogFile -LogMessage "WARNING - Check virtual machine $TemplateWin2k12r2Std status" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            Disconnect-VIServer -Server $vCenterServer -Confirm:$false
            Write-MessageToLogFile -LogMessage "INFORMATION - Script successfully disconnected from vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            exit
        }
        $CheckCounter++
    } while ($CurrentDateTimeStamp -gt ($TemplateWin2k12r2StdRegLDTasDate.AddHours($AddHoursLocationVsUTC)))

    Write-MessageToLogFile -LogMessage "INFORMATION - Last Windows update check $TemplateWin2k12r2StdRegLDT (UTC Time)" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    Write-MessageToLogFile -LogMessage "INFORMATION - Windows Update check finished" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
} else {
    Write-MessageToLogFile -LogMessage "INFORMATION - New Windows update check is not needed" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
}
Start-Sleep -Seconds 30

# Checking if Windows Update are pending for installation
Write-MessageToLogFile -LogMessage "INFORMATION - Checking for Windows updates pending to install" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
$CheckCounter = 0
Clear-Variable -Name CurrentDateTimeStamp
$CurrentDateTimeStamp = Get-Date
$TemplateWin2k12r2StdRegNFUAFI = Invoke-Command -ComputerName $TemplateWin2k12r2StdIPAddress -ScriptBlock {Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -Name NonFirmwareUpdatesAvailableForInstall} -Credential $CredentialsToAccessTemplate
$TemplateWin2k12r2StdRegUAFDL = Invoke-Command -ComputerName $TemplateWin2k12r2StdIPAddress -ScriptBlock {Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -Name UpdatesAvailableForDownloadLogon} -Credential $CredentialsToAccessTemplate
$TemplateWin2k12r2StdRegUAFIL = Invoke-Command -ComputerName $TemplateWin2k12r2StdIPAddress -ScriptBlock {Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -Name UpdatesAvailableForInstallLogon} -Credential $CredentialsToAccessTemplate
$TemplateWin2k12r2StdRegUAWUOEL = Invoke-Command -ComputerName $TemplateWin2k12r2StdIPAddress -ScriptBlock {Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -Name UpdatesAvailableWithUiOrEulaLogon} -Credential $CredentialsToAccessTemplate
$TemplateWin2k12r2StdRegUAWUL = Invoke-Command -ComputerName $TemplateWin2k12r2StdIPAddress -ScriptBlock {Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -Name UpdatesAvailableWithUiLogon} -Credential $CredentialsToAccessTemplate

if (($TemplateWin2k12r2StdRegNFUAFI -gt 0) -or ($TemplateWin2k12r2StdRegUAFDL -gt 0) -or ($TemplateWin2k12r2StdRegUAFIL -gt 0) -or ($TemplateWin2k12r2StdRegUAWUOEL -gt 0) -or ($TemplateWin2k12r2StdRegUAWUL -gt 0)) {
    Write-MessageToLogFile -LogMessage "INFORMATION - Installing Windows updates" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    Invoke-Command -ComputerName $TemplateWin2k12r2StdIPAddress -ScriptBlock {& C:\Windows\System32\wuauclt.exe /UpdateNow} -Credential $CredentialsToAccessTemplate
    
    do {
        $TemplateWin2k12r2StdRegLIT = $null
        $TemplateWin2k12r2StdRegLITasDate = $null
        
        Start-Sleep -Seconds 15

        $TemplateWin2k12r2StdRegLIT = Invoke-Command -ComputerName $TemplateWin2k12r2StdIPAddress -ScriptBlock {Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install' -Name LastSuccessTime} -Credential $CredentialsToAccessTemplate
        $TemplateWin2k12r2StdRegLITasDate = [DateTime]::ParseExact($TemplateWin2k12r2StdRegLIT, 'yyyy-MM-dd HH:mm:ss', $CultureInfo)
        
        if ($CheckCounter -ge 1920) {
            # 1920 is value equal to 8 hours (Each check is performed in 15 seconds. 60 seconds/15 is 4. 4 multiple by 60 is 1 hour (240). 240 multiple by 8 is eight hours)
            Write-MessageToLogFile -LogMessage "ERROR - Check counter exceeded limit, virtual machine $TemplateWin2k12r2Std status did not meet conditions to be successfully updated" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            Start-Sleep -Seconds 5
            Write-MessageToLogFile -LogMessage "INFORMATION - Powering off virtual machine $TemplateWin2k12r2Std" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            Get-VM -Name $TemplateWin2k12r2Std | Stop-VM -Confirm:$false
            Write-MessageToLogFile -LogMessage "WARNING - Check virtual machine $TemplateWin2k12r2Std status" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            Disconnect-VIServer -Server $vCenterServer -Confirm:$false
            Write-MessageToLogFile -LogMessage "INFORMATION - Script successfully disconnected from vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            exit
        }
        $CheckCounter++
    } while ($CurrentDateTimeStamp -gt ($TemplateWin2k12r2StdRegLITasDate.AddHours($AddHoursLocationVsUTC)))
    
    Write-MessageToLogFile -LogMessage "INFORMATION - Windows updates last successfful installation time $TemplateWin2k12r2StdRegLIT (UTC Time)" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
} else {
    Write-MessageToLogFile -LogMessage "INFORMATION - No Windows updates pending for installation" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
}
Start-Sleep -Seconds 30

# Chekking if Windows update finished and rebooting server
$CheckCounter = 0

if ((Invoke-Command -ComputerName $TemplateWin2k12r2StdIPAddress -ScriptBlock {Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"} -Credential $CredentialsToAccessTemplate) -or (Invoke-Command -ComputerName $TemplateWin2k12r2StdIPAddress -ScriptBlock {Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting"} -Credential $CredentialsToAccessTemplate) -or (Invoke-Command -ComputerName $TemplateWin2k12r2StdIPAddress -ScriptBlock {Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"} -Credential $CredentialsToAccessTemplate) -or (Invoke-Command -ComputerName $TemplateWin2k12r2StdIPAddress -ScriptBlock {Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending"} -Credential $CredentialsToAccessTemplate)) {
    Write-MessageToLogFile -LogMessage "INFORMATION - Windows updates has been installed on server $TemplateWin2k12r2Std, OS with name $TemplateWin2k12r2StdHostName" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    Get-VM -Name $TemplateWin2k12r2Std | Restart-VMGuest -Confirm:$false

    Start-Sleep -Seconds 30

    do {
        Write-MessageToLogFile -LogMessage "INFORMATION - Reboot in progress" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"

        $TemplateWin2k12r2StdGuestState = $null
        $TemplateWin2k12r2StdVMToolsStatus = $null
        $TemplateWin2k12r2StdHeartBeatStatus = $null
        $TemplateWin2k12r2StdOverallStatus = $null

        Start-Sleep -Seconds 15

        $TemplateWin2k12r2StdGuestState = (Get-VM -Name $TemplateWin2k12r2Std | Get-View).Guest.GuestState
        $TemplateWin2k12r2StdVMToolsStatus = (Get-VM -Name $TemplateWin2k12r2Std | Get-View).Guest.ToolsStatus
        $TemplateWin2k12r2StdHeartBeatStatus = (Get-VM -Name $TemplateWin2k12r2Std | Get-View).GuestHeartbeatStatus
        $TemplateWin2k12r2StdOverallStatus = (Get-VM -Name $TemplateWin2k12r2Std | Get-View).OverallStatus
        
        if ($CheckCounter -ge 1920) {
            # 1920 is value equal to 8 hours (Each check is performed in 15 seconds. 60 seconds/15 is 4. 4 multiple by 60 is 1 hour (240). 240 multiple by 8 is eight hours)
            Write-MessageToLogFile -LogMessage "ERROR - Check counter exceeded limit, virtual machine $TemplateWin2k12r2Std status did not meet conditions to be successfully updated" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            Start-Sleep -Seconds 5
            Write-MessageToLogFile -LogMessage "INFORMATION - Powering off virtual machine $TemplateWin2k12r2Std" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            Get-VM -Name $TemplateWin2k12r2Std | Stop-VM -Confirm:$false
            Write-MessageToLogFile -LogMessage "WARNING - Check virtual machine $TemplateWin2k12r2Std status" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            Disconnect-VIServer -Server $vCenterServer -Confirm:$false
            Write-MessageToLogFile -LogMessage "INFORMATION - Script successfully disconnected from vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            exit
        }
        $CheckCounter++
    } while (($TemplateWin2k12r2StdGuestState -like 'running') -and ($TemplateWin2k12r2StdVMToolsStatus -like 'toolsOk') -and ($TemplateWin2k12r2StdHeartBeatStatus -like 'green') -and ($TemplateWin2k12r2StdOverallStatus -like 'green'))

    do {
        Write-MessageToLogFile -LogMessage "INFORMATION - Reboot in progress" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"

        $TemplateWin2k12r2StdGuestState = $null
        $TemplateWin2k12r2StdVMToolsStatus = $null
        $TemplateWin2k12r2StdHeartBeatStatus = $null
        $TemplateWin2k12r2StdOverallStatus = $null

        Start-Sleep -Seconds 15

        $TemplateWin2k12r2StdGuestState = (Get-VM -Name $TemplateWin2k12r2Std | Get-View).Guest.GuestState
        $TemplateWin2k12r2StdVMToolsStatus = (Get-VM -Name $TemplateWin2k12r2Std | Get-View).Guest.ToolsStatus
        $TemplateWin2k12r2StdHeartBeatStatus = (Get-VM -Name $TemplateWin2k12r2Std | Get-View).GuestHeartbeatStatus
        $TemplateWin2k12r2StdOverallStatus = (Get-VM -Name $TemplateWin2k12r2Std | Get-View).OverallStatus
        
        if ($CheckCounter -ge 1920) {
            # 1920 is value equal to 8 hours (Each check is performed in 15 seconds. 60 seconds/15 is 4. 4 multiple by 60 is 1 hour (240). 240 multiple by 8 is eight hours)
            Write-MessageToLogFile -LogMessage "ERROR - Check counter exceeded limit, virtual machine $TemplateWin2k12r2Std status did not meet conditions to be successfully updated" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            Start-Sleep -Seconds 5
            Write-MessageToLogFile -LogMessage "INFORMATION - Powering off virtual machine $TemplateWin2k12r2Std" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            Get-VM -Name $TemplateWin2k12r2Std | Stop-VM -Confirm:$false
            Write-MessageToLogFile -LogMessage "WARNING - Check virtual machine $TemplateWin2k12r2Std status" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            Disconnect-VIServer -Server $vCenterServer -Confirm:$false
            Write-MessageToLogFile -LogMessage "INFORMATION - Script successfully disconnected from vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            exit
        }
        $CheckCounter++
    } until (($TemplateWin2k12r2StdGuestState -like 'running') -and ($TemplateWin2k12r2StdVMToolsStatus -like 'toolsOk') -and ($TemplateWin2k12r2StdHeartBeatStatus -like 'green') -and ($TemplateWin2k12r2StdOverallStatus -like 'green'))

    Write-MessageToLogFile -LogMessage "INFORMATION - Server rebooted" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    Write-MessageToLogFile -LogMessage "INFORMATION - Shutting down server $TemplateWin2k12r2Std, OS with name $TemplateWin2k12r2StdHostName" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    Get-VM -Name $TemplateWin2k12r2Std | Shutdown-VMGuest -Confirm:$false

    Start-Sleep -Seconds 30

    do {
        $TemplateWin2k12r2StdPowerState = $null
        
        Start-Sleep -Seconds 15
        
        $TemplateWin2k12r2StdPowerState = (Get-VM -Name $TemplateWin2k12r2Std).PowerState
        
        if ($CheckCounter -ge 1920) {
            # 1920 is value equal to 8 hours (Each check is performed in 15 seconds. 60 seconds/15 is 4. 4 multiple by 60 is 1 hour (240). 240 multiple by 8 is eight hours)
            Write-MessageToLogFile -LogMessage "ERROR - Check counter exceeded limit, virtual machine $TemplateWin2k12r2Std status did not meet conditions to be successfully updated" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            Start-Sleep -Seconds 5
            Write-MessageToLogFile -LogMessage "INFORMATION - Powering off virtual machine $TemplateWin2k12r2Std" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            Get-VM -Name $TemplateWin2k12r2Std | Stop-VM -Confirm:$false
            Write-MessageToLogFile -LogMessage "WARNING - Check virtual machine $TemplateWin2k12r2Std status" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            Disconnect-VIServer -Server $vCenterServer -Confirm:$false
            Write-MessageToLogFile -LogMessage "INFORMATION - Script successfully disconnected from vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            exit
        }
        $CheckCounter++
    } until ($TemplateWin2k12r2StdPowerState -like 'PoweredOff')
    
    $TemplateWin2k12r2StdVMNotes = Get-VM -Name $TemplateWin2k12r2Std | Select-Object -ExpandProperty Notes
    [int]$LastIndexOfColon = $TemplateWin2k12r2StdVMNotes.LastIndexOf(":")+1
    $TemplateWin2k12r2StdVMNotes = $TemplateWin2k12r2StdVMNotes.Remove($LastIndexOfColon)
    $TemplateWin2k12r2StdVMNotesLastUpdateDate = Get-Date -Format dd-MM-yyyy
    $TemplateWin2k12r2StdVMNotes = $TemplateWin2k12r2StdVMNotes.Insert($LastIndexOfColon," $TemplateWin2k12r2StdVMNotesLastUpdateDate")
    Set-VM -VM $TemplateWin2k12r2Std -Notes $TemplateWin2k12r2StdVMNotes -Confirm:$false

    Write-MessageToLogFile -LogMessage "INFORMATION - Converting virtual $TemplateWin2k12r2Std machine into template" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    Get-VM -Name $TemplateWin2k12r2Std | Set-VM -ToTemplate -Confirm:$false

} else {
    Write-MessageToLogFile -LogMessage "INFORMATION - Shutting down server $TemplateWin2k12r2Std, OS with name $TemplateWin2k12r2StdHostName" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    Get-VM -Name $TemplateWin2k12r2Std | Shutdown-VMGuest -Confirm:$false

    Start-Sleep -Seconds 30
    
    do {
        $TemplateWin2k12r2StdPowerState = $null
        
        Start-Sleep -Seconds 15
        $TemplateWin2k12r2StdPowerState = (Get-VM -Name $TemplateWin2k12r2Std).PowerState
        
        if ($CheckCounter -ge 1920) {
            # 1920 is value equal to 8 hours (Each check is performed in 15 seconds. 60 seconds/15 is 4. 4 multiple by 60 is 1 hour (240). 240 multiple by 8 is eight hours)
            Write-MessageToLogFile -LogMessage "ERROR - Check counter exceeded limit, virtual machine $TemplateWin2k12r2Std status did not meet conditions to be successfully updated" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            Start-Sleep -Seconds 5
            Write-MessageToLogFile -LogMessage "INFORMATION - Powering off virtual machine $TemplateWin2k12r2Std" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            Get-VM -Name $TemplateWin2k12r2Std | Stop-VM -Confirm:$false
            Write-MessageToLogFile -LogMessage "WARNING - Check virtual machine $TemplateWin2k12r2Std status" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            Disconnect-VIServer -Server $vCenterServer -Confirm:$false
            Write-MessageToLogFile -LogMessage "INFORMATION - Script successfully disconnected from vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
            exit
        }
        $CheckCounter++
    } until ($TemplateWin2k12r2StdPowerState -like 'PoweredOff')
    
    # Updating VM notes
    $TemplateWin2k12r2StdVMNotes = Get-VM -Name $TemplateWin2k12r2Std | Select-Object -ExpandProperty Notes
    [int]$LastIndexOfColon = $TemplateWin2k12r2StdVMNotes.LastIndexOf(":")+1
    $TemplateWin2k12r2StdVMNotes = $TemplateWin2k12r2StdVMNotes.Remove($LastIndexOfColon)
    $TemplateWin2k12r2StdVMNotesLastUpdateDate = Get-Date -Format dd-MM-yyyy
    $TemplateWin2k12r2StdVMNotes = $TemplateWin2k12r2StdVMNotes.Insert($LastIndexOfColon," $TemplateWin2k12r2StdVMNotesLastUpdateDate")
    Set-VM -VM $TemplateWin2k12r2Std -Notes $TemplateWin2k12r2StdVMNotes -Confirm:$false

    Write-MessageToLogFile -LogMessage "INFORMATION - Converting virtual $TemplateWin2k12r2Std machine into template" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"
    Get-VM -Name $TemplateWin2k12r2Std | Set-VM -ToTemplate -Confirm:$false
}

Write-MessageToLogFile -LogMessage "INFORMATION - Script has completed all steps" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"

Disconnect-VIServer -Server $vCenterServer -Confirm:$false
Write-MessageToLogFile -LogMessage "INFORMATION - Script successfully disconnected from vCenter $vCenterServer" -LogFilePath "$env:ProgramData\vmware-templates-maintenance\win2k12\$TemplateWin2k12r2Std-$NewLogDateWin2k12r2Std.txt"

Get-ChildItem -Path "$env:ProgramData\vmware-templates-maintenance\" -Filter "ops_run_*.txt" | Remove-Item -Confirm:$false