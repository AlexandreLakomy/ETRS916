param (
    [string]$ProcessName,
    [switch]$Kill
)

if ($ProcessName) {

    $proc = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue

    if (-not $proc) {
        Write-Host "Process '$ProcessName' not found"
        exit 1
    }

    Write-Output ($proc | Select-Object Name, Id)

    if ($Kill) {
        Stop-Process -Id $proc.Id -Force
        Write-Host "Process '$ProcessName' killed"
    }

}
else {
    Write-Output (Get-Process | Select-Object Name, Id)
}
