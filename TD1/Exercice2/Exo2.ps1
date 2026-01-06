$LogDir = "C:\Temp"
$LogFile = "Temp\Exo2.log"
$RegPath = "HKLM:\Software\Policies\Microsoft\Windows NT\DNSClient"
$ValueName = "EnableMulticast"

if (-not (Test-Path $LogDir)) {
    New-Item -Path $LogDir -ItemType Directory | Out-Null
}

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "$timestamp [$Level] $Message"
}

if (-not (Test-Path $RegPath)) {
    Write-Log "Registry key does not exist. Creating it."
    New-Item -Path $RegPath -Force | Out-Null
}
else {
    Write-Log "Registry key already exists."
}

$existingValue = Get-ItemPropertyValue `
    -Path $RegPath `
    -Name $ValueName `
    -ErrorAction SilentlyContinue

if ($null -eq $existingValue) {
    Write-Log "Registry value '$ValueName' does not exist. Creating it with value 0."
    New-ItemProperty `
        -Path $RegPath `
        -Name $ValueName `
        -PropertyType DWord `
        -Value 0 `
        -Force | Out-Null
}
else {
    Write-Log "Registry value '$ValueName' already exists."
}
