$ErrorActionPreference = 'Stop'

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Output "Downloading OpenSSH"
$releases = "https://api.github.com/repos/PowerShell/Win32-OpenSSH/releases/latest"
$latest = Invoke-RestMethod $releases
$asset = $latest.assets | Where-Object Name -Like "*Win64.zip"
Invoke-WebRequest -Uri  $asset.browser_download_url -OutFile OpenSSH-Win64.zip -UseBasicParsing

Write-Output "Expanding OpenSSH"
Expand-Archive OpenSSH-Win64.zip $env:ProgramData
Remove-Item -Force OpenSSH-Win64.zip

Push-Location $env:ProgramData\OpenSSH-Win64
Write-Output "Enable logfile"
((Get-Content -Path sshd_config_default -Raw) -replace '#SyslogFacility AUTH', 'SyslogFacility LOCAL0') | Set-Content -Path sshd_config_default
# Write-Output "Disabling password authentication"
# ((Get-Content -path sshd_config_default -Raw) -replace '#PasswordAuthentication yes','PasswordAuthentication no') | Set-Content -Path sshd_config_default
Write-Output "Enable empty password"
((Get-Content -Path sshd_config_default -Raw) -replace '#PermitEmptyPasswords no', 'PermitEmptyPasswords yes') | Set-Content -Path sshd_config_default

Write-Output "Installing OpenSSH"
& .\install-sshd.ps1


Write-Output "Fixing host file permissions"
& .\FixHostFilePermissions.ps1 -Confirm:$false

Write-Output "Fixing user file permissions"
& .\FixUserFilePermissions.ps1 -Confirm:$false

Pop-Location

$newPath = '$env:ProgramData\OpenSSH-Win64;' + [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("PATH", $newPath, [EnvironmentVariableTarget]::Machine)

# Write-Output "Adding public key to authorized_keys"
# $keyPath = "~\\.ssh\\authorized_keys"
# New-Item -Type Directory ~\\.ssh > $null
# $sshKey | Out-File $keyPath -Encoding Ascii

# Write-Output "Opening firewall port 22"
# New-NetFirewallRule -Protocol TCP -LocalPort 22 -Direction Inbound -Action Allow -DisplayName SSH
Write-Output "Setting pwsh as default shell"
$pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
if ($pwsh) {
    New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value $pwsh.source -PropertyType String -Force | Out-Null
}
else {
    Write-Output "could not find pwsh.exe. Setting Windows Powershell default"
    New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force | Out-Null
}

# Setting ACL on openssl folder
#Get-Acl .\\OpenSSH-Win64\\ | Set-Acl .\\OpenSSH-Win64\\


Write-Output "Setting sshd service startup type to 'Automatic'"
Set-Service sshd -StartupType Automatic
Set-Service ssh-agent -StartupType Automatic
Write-Output "Setting sshd service restart behavior"
sc.exe failure sshd reset= 86400 actions= restart/500
Write-Output "Starting Service sshd"
Start-Service sshd 
Get-Service sshd