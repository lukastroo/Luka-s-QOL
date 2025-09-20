<# system-tweaks.ps1
Tasks:
- Delete temp files
- Disable consumer features
- Disable telemetry
- Disable activity history
- Disable Explorer automatic folder type discovery
- Disable GameDVR
- Disable HomeGroup
- Disable location tracking
- Disable Storage Sense
- Disable Wi-Fi Sense
- Enable “End task” on taskbar right-click
- Disable PowerShell 7 + .NET CLI telemetry
- Set selected services to Manual/Disabled
- Set timezone to Belgium (Romance Standard Time)
#>

[CmdletBinding()]
param()

function Assert-Admin {
  if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run this in an elevated PowerShell."
  }
}

function Set-Reg {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)]$Value,
    [Microsoft.Win32.RegistryValueKind]$Type=[Microsoft.Win32.RegistryValueKind]::Unknown
  )
  if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
  if ($Type -eq [Microsoft.Win32.RegistryValueKind]::Unknown) {
    $Type = ($Value -is [int]) ? [Microsoft.Win32.RegistryValueKind]::DWord : [Microsoft.Win32.RegistryValueKind]::String
  }
  New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

function Try-SetService {
  param([string]$Name,[string]$StartupType,[string]$StatusIfRunning="Stop")
  $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
  if ($null -ne $svc) {
    if ($StartupType) { Set-Service -Name $Name -StartupType $StartupType -ErrorAction SilentlyContinue }
    if ($StatusIfRunning -and $svc.Status -eq 'Running') {
      if ($StatusIfRunning -eq 'Stop') { Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue }
    }
  }
}

Assert-Admin

Write-Host "1) Delete temp files"
$targets = @(
  "$env:TEMP\*",
  "$env:WINDIR\Temp\*",
  "$env:WINDIR\SoftwareDistribution\Download\*",
  "$env:ProgramData\Microsoft\Windows\DeliveryOptimization\Cache\*"
)
foreach ($t in $targets) { Remove-Item $t -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host "2) Disable consumer features"
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableConsumerFeatures' 1
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableTailoredExperiencesWithDiagnosticData' 1
Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338387Enabled' 0
Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338388Enabled' 0
Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-314563Enabled' 0

Write-Host "3) Disable telemetry"
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0
Try-SetService 'DiagTrack' 'Disabled' 'Stop'
Try-SetService 'dmwappushservice' 'Disabled' 'Stop'

Write-Host "4) Disable activity history"
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableActivityFeed' 0
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'PublishUserActivities' 0
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'UploadUserActivities' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy' 'ActivityFeedEnabled' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy' 'PublishUserActivities' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy' 'UploadUserActivities' 0

Write-Host "5) Disable Explorer automatic folder type discovery"
Set-Reg 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell' 'NoFolderTypeDiscovery' 1
Set-Reg 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell' 'FolderType' 'NotSpecified'
Set-Reg 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags' 'AllFoldersChecked' 1
Set-Reg 'HKCU:\Software\Microsoft\Windows\Shell' 'BagMRU Size' 20000

Write-Host "6) Disable GameDVR"
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 0
Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
Try-SetService 'XblAuthManager' 'Disabled' 'Stop'
Try-SetService 'XblGameSave' 'Disabled' 'Stop'
Try-SetService 'XboxGipSvc' 'Disabled' 'Stop'
Try-SetService 'XboxNetApiSvc' 'Disabled' 'Stop'

Write-Host "7) Disable HomeGroup (legacy, if present)"
Try-SetService 'HomeGroupListener' 'Disabled' 'Stop'
Try-SetService 'HomeGroupProvider' 'Disabled' 'Stop'

Write-Host "8) Disable location tracking"
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocation' 1
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocationScripting' 1
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableSensors' 1
$cap = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'
Set-Reg $cap 'Value' 'Deny'

Write-Host "9) Disable Storage Sense"
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\StorageSense' 'AllowStorageSenseGlobal' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy' '01' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy' 'StoragePoliciesNotified' 1

Write-Host "10) Disable Wi-Fi Sense"
Set-Reg 'HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config' 'AutoConnectAllowedOEM' 0
Set-Reg 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting' 'value' 0
Set-Reg 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots' 'value' 0

Write-Host "11) Enable End task on taskbar right-click"
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarEndTask' 1

Write-Host "12) Disable PowerShell 7 and .NET CLI telemetry"
[Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT','1','Machine')
[Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT','1','Machine')
[Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT','1','User')
[Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT','1','User')

Write-Host "13) Services to Manual/Disabled (safe subset)"
Try-SetService 'diagnosticshub.standardcollector.service' 'Disabled' 'Stop'
Try-SetService 'PcaSvc' 'Manual'
Try-SetService 'WerSvc' 'Manual'
Try-SetService 'MapsBroker' 'Manual' 'Stop'
Try-SetService 'DoSvc' 'Manual'
Try-SetService 'RetailDemo' 'Disabled' 'Stop'

Write-Host "14) Set timezone to Belgium"
Set-TimeZone -Id "Romance Standard Time"

Write-Host "Done. Sign out or reboot for all changes to apply."
