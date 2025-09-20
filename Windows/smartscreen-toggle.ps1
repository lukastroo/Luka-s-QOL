<# smartscreen-toggle.ps1
Usage examples:

# 1) Disable only PUA blocking (Defender AV)
#    .\smartscreen-toggle.ps1 -PUA Disabled
#
# 2) Disable "Check apps and files" (Explorer), Edge SmartScreen, and Store-app SmartScreen
#    .\smartscreen-toggle.ps1 -Explorer Off -Edge Off -Store Off
#
# 3) Re-enable everything
#    .\smartscreen-toggle.ps1 -PUA Enabled -Explorer Warn -Edge On -EdgePUA On -Store On -Phishing On
#>

[CmdletBinding(SupportsShouldProcess)]
param(
  [ValidateSet('Disabled','Enabled','Audit')]
  [string]$PUA,

  # Explorer "Check apps and files" control
  # Values: Off | Warn
  [ValidateSet('Off','Warn')]
  [string]$Explorer,

  # Edge SmartScreen core toggle
  [ValidateSet('On','Off')]
  [string]$Edge,

  # Edge PUA blocking toggle
  [ValidateSet('On','Off')]
  [string]$EdgePUA,

  # SmartScreen for Microsoft Store apps
  [ValidateSet('On','Off')]
  [string]$Store,

  # Enhanced Phishing Protection (Windows Security > App & browser control)
  [ValidateSet('On','Off')]
  [string]$Phishing
)

function Assert-Admin {
  if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run this in an elevated PowerShell (Administrator)."
  }
}

function Set-RegistryValue {
  param(
    [Parameter(Mandatory)] [string]$Path,
    [Parameter(Mandatory)] [string]$Name,
    [Parameter(Mandatory)] $Value,
    [Microsoft.Win32.RegistryValueKind]$Type = [Microsoft.Win32.RegistryValueKind]::Unknown
  )
  if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
  if ($Type -eq [Microsoft.Win32.RegistryValueKind]::Unknown) {
    # Infer type
    if ($Value -is [int]) { $Type = [Microsoft.Win32.RegistryValueKind]::DWord }
    elseif ($Value -is [string]) { $Type = [Microsoft.Win32.RegistryValueKind]::String }
    else { $Type = [Microsoft.Win32.RegistryValueKind]::String }
  }
  New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

Assert-Admin

# 1) Potentially Unwanted Apps (Defender AV)
if ($PSBoundParameters.ContainsKey('PUA')) {
  $map = @{
    'Disabled' = 0    # off
    'Enabled'  = 1    # block
    'Audit'    = 2    # audit only
  }
  Write-Host "Setting Defender PUAProtection to $PUA ($($map[$PUA]))"
  Set-MpPreference -PUAProtection $map[$PUA]
}

# 2) Explorer "Check apps and files" (SmartScreen for apps and files)
#    HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer  SmartScreenEnabled = "Off" | "Warn"
if ($PSBoundParameters.ContainsKey('Explorer')) {
  Write-Host "Setting Explorer SmartScreen (Check apps and files) to $Explorer"
  Set-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'SmartScreenEnabled' -Value $Explorer -Type String
}

# 3) Microsoft Edge SmartScreen + PUA via policies
#    HKLM\SOFTWARE\Policies\Microsoft\Edge  SmartScreenEnabled (DWORD) 1/0
#    HKLM\SOFTWARE\Policies\Microsoft\Edge  SmartScreenPuaEnabled (DWORD) 1/0
if ($PSBoundParameters.ContainsKey('Edge')) {
  $v = @{'On'=1; 'Off'=0}[$Edge]
  Write-Host "Setting Edge SmartScreen to $Edge"
  Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'SmartScreenEnabled' -Value $v -Type DWord
}
if ($PSBoundParameters.ContainsKey('EdgePUA')) {
  $v = @{'On'=1; 'Off'=0}[$EdgePUA]
  Write-Host "Setting Edge PUA to $EdgePUA"
  Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'SmartScreenPuaEnabled' -Value $v -Type DWord
}

# 4) SmartScreen for Microsoft Store apps
#    HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost  EnableWebContentEvaluation (DWORD) 1/0
if ($PSBoundParameters.ContainsKey('Store')) {
  $v = @{'On'=1; 'Off'=0}[$Store]
  Write-Host "Setting SmartScreen for Microsoft Store apps to $Store"
  Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AppHost' -Name 'EnableWebContentEvaluation' -Value $v -Type DWord
}

# 5) Enhanced Phishing Protection (user scope)
#    HKCU\Software\Microsoft\Windows\CurrentVersion\SmartScreen\EnhancedMode (DWORD) 1/0
#    If key path does not exist on some builds, create it.
if ($PSBoundParameters.ContainsKey('Phishing')) {
  $v = @{'On'=1; 'Off'=0}[$Phishing]
  Write-Host "Setting Enhanced Phishing Protection to $Phishing"
  Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SmartScreen' -Name 'EnhancedMode' -Value $v -Type DWord
}

Write-Host "Done. You may need to restart Windows Security UI or sign out/in to see toggles reflect."
