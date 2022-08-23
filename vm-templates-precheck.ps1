# >>>> Check TrustedHosts value <<<<
Write-Host "Checking TrusteHosts" -ForegroundColor Green
Get-ChildItem -Path WSMan:\localhost\Client\TrustedHosts

$TrustedHostsQ = Read-Host "Is TrustedHosts set correctly? (Y/N)"
if ($TrustedHostsQ -eq 'N') {
   $TrustedHostsValue = Read-Host "Enter IP adresses"
   Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$TrustedHostsValue" -Confirm:$false -Force
   Write-Host "TrustedHosts set"
   Get-ChildItem -Path WSMan:\localhost\Client\TrustedHosts
} else {
    Write-Host "No chage to TrustedHosts"
}

# >>>> Check PowerCLI module value <<<<
if (Get-InstalledModule | Where-Object {$_.Name -like 'VMware.PowerCLI'}) {
    Write-Host "VMware PowerCLI module is installed" -ForegroundColor Green
} else {
    Write-Host "VMware PowerCLI module is not installed" -ForegroundColor Red
}

# >>>> Genearte Password ONLY for first time <<<<
$GeneratePasswordFileQ = Read-Host "Would you like to generate password file for accounts? (Y/N)"
if ($GeneratePasswordFileQ -eq 'Y') {
    # Password for '<user name>@<domain name>'
    Write-Host "Creating password for '<user name>@<domain name>'" -ForegroundColor Green
    Read-Host "Enter password" -AsSecureString | ConvertFrom-SecureString | Out-File "$env:ProgramData\vmware-templates-maintenance\eid.txt"
    # Password for local Administrator
    Write-Host "Creating password for 'Administrator'" -ForegroundColor Green
    Read-Host "Enter password" -AsSecureString | ConvertFrom-SecureString | Out-File "$env:ProgramData\vmware-templates-maintenance\mid.txt"
} else {
    Write-Host "No password files will be generated"
}
