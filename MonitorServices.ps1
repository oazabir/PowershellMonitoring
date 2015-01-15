param (    
    [Parameter(Mandatory=$true)][string]$names,
    [string]$logFile
)
$serviceNames = $names.Split(',')

function log($logFile, $log) {
    Write-Host $log
    if (-not [string]::IsNullOrEmpty($logFile)) { Add-Content $logFile $log }
}


if (-not [string]::IsNullOrEmpty($logFile)) {
    if (Test-Path $logFile) { 
        rm $logFile 
    }
}

foreach ($service in $serviceNames) {
    $service = get-service $service 
    log $logFile $($service.Name + ' ' + $service.Status)
}


# Success: Running
# Problem: Stoppped, Disabled