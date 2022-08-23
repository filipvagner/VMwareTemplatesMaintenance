$JobTriggerParameters = @{
    Frequency = "Weekly"
    At = "1:00AM"
    DaysOfWeek = "Sunday"
}

$JobOptionParameters = @{
    WakeToRun = $true
    #ContinueIfGoingOnBattery = $true
    # StartIfOnBattery = $true
    RunElevated = $true
}

$ScheduledJobName = "vm-templatewin2k16std-maintenance"
$ScheduledJobFilePath = "$env:ProgramData\vmware-templates-maintenance\vm-templatewin2k16std-maintenance.ps1"
$ScheduledJobCredentials = (Get-Credential)
Register-ScheduledJob -Name $ScheduledJobName -FilePath $ScheduledJobFilePath -Trigger $JobTriggerParameters -ScheduledJobOption $JobOptionParameters -Credential $ScheduledJobCredentials

# To disable scheduled job Template 2016
# Get-ScheduledJob -Name 'vm-templatewin2k16std-maintenance' | Disable-ScheduledJob
# To disable scheduled job Template 2012
# Get-ScheduledJob -Name 'vm-templateWin2k12r2std-maintenance' | Disable-ScheduledJob

# To enable scheduled job Template 2016
# Get-ScheduledJob -Name 'vm-templatewin2k16std-maintenance' | Enable-ScheduledJob
# To enable scheduled job Template 2012
# Get-ScheduledJob -Name 'vm-templateWin2k12r2std-maintenance' | Enable-ScheduledJob

# To remove (unregister) scheduled job Template 2016
# Get-ScheduledJob -Name 'vm-templatewin2k16std-maintenance' | Unregister-ScheduledJob
# To remove (unregister) scheduled job Template 2012
# Get-ScheduledJob -Name 'vm-templateWin2k12r2std-maintenance' | Unregister-ScheduledJob