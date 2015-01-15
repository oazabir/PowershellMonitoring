param (
    [Parameter(Mandatory=$true)][string]$poolName="DefaultAppPool",
    [string]$logFile
)
Import-Module WebAdministration; 

$Output = Get-WebAppPoolState –name "$poolName"

function log($logFile, $log) {
    Write-Host $log
    if (-not [string]::IsNullOrEmpty($logFile)) { Set-Content $logFile $log }
}

log $logFile $Output.Value

# Success: Started
# Problem: Stopped, Disabled