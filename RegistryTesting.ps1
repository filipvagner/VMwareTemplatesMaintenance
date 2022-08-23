

Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" # Beofre reboot EXIST > Verify after reboot KEY > TO BE USED TO TEST
Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting" # Beofre reboot DOES NOT EXIST > TO BE USED TO TEST
Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" # Beofre reboot EXIST > Verify after reboot KEY > TO BE USED TO TEST
Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending" # Beofre reboot EXIST > Verify after reboot KEY > TO BE USED TO TEST

if ((Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") -or (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting") -or (Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") -or (Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending")) {
    
}

#Another keys to test porgress
Write-Host "Auto Update status"
Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\"
Write-Host "Detect status"
Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Detect"
Write-Host "Download status"
Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Download"
Write-Host "Install status"
Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install"
Write-Host "Services status"
Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Services"
Write-Host "Pedning status"
Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Services\Pending"
Write-Host "Setup status"
Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Setup"
Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Setup"