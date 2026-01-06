$Rules = @(
    @{
        Name = "WinRM HTTP 5985"
        Port = 5985
    },
    @{
        Name = "WinRM HTTPS 5986"
        Port = 5986
    }
)

foreach ($rule in $Rules) {

    $existingRule = Get-NetFirewallRule `
        -DisplayName $rule.Name `
        -ErrorAction SilentlyContinue

    if (-not $existingRule) {

        New-NetFirewallRule `
            -DisplayName $rule.Name `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPort $rule.Port `
            -Action Allow `
            -RemoteAddress Any `
            -Group "Windows Remote Management" | Out-Null
    }
}

# Vérification finale
$allOk = $true

foreach ($rule in $Rules) {

    $fwRule = Get-NetFirewallRule `
        -DisplayName $rule.Name `
        -ErrorAction SilentlyContinue

    if (-not $fwRule -or -not $fwRule.Enabled) {
        Write-Host "Rule '$($rule.Name)' is missing or disabled" -ForegroundColor Red
        $allOk = $false
    }
}

if ($allOk) {
    Write-Host "WinRM firewall configuration is correct (ports 5985 and 5986 are open)" -ForegroundColor Green
}
else {
    Write-Host "WinRM firewall configuration is NOT correct" -ForegroundColor Red
}
