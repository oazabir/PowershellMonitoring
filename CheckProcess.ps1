param (
    [Parameter(Mandatory=$true)][string]$ProcessNameToCheck,
    [string]$logFile
)

function log($logFile, $log) {
    Write-Host $log
    if (-not [string]::IsNullOrEmpty($logFile)) { Set-Content $logFile $log }
}

$ProcessIsRunning = Get-Process $ProcessNameToCheck -ErrorAction SilentlyContinue
if ($ProcessIsRunning) {
    log $logFile "Running"    
} 
else {
    log $logFile "Not running"
}

# Success: Running
# Problem: Not running