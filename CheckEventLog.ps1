param (
    [string]$LogName="System",
    [string]$EntryType="Error",
    [int]$LastNMinutes=10,  # Get events logs in last N minutes
    [int]$Ignore=0, # Log only if number of event log entries are over this
    [string]$SourceFilter="", # e.g ASP.NET
    [string]$logFile
)
function log($logFile, $log) {
    Write-Host $log
    if (-not [string]::IsNullOrEmpty($logFile)) { Set-Content $logFile $log }
}

log $logFile $Output.Value
$date = [DateTime]::Now.AddMinutes(-$LastNMinutes)
$logs = get-eventlog $LogName -After $date -EntryType $EntryType | Where-Object { ($SourceFilter.Length -eq 0) -or ($_.Source -match $SourceFilter) }
if ($logs) {
    if ($logs.Length -gt $Ignore) {
        log $logFile "Found"
        $logs | % { log $logFile "$($_.Index.ToString()) $($_.TimeWritten.ToString()) $($_.EntryType.ToString()) $($_.Source.ToString()) $($_.Message.ToString())" }
    }
}