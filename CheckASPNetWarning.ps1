param (
    [string]$LogName="Application",
    [string]$EntryType="Warning",
    [int]$LastNMinutes=10,  # Get events logs in last N minutes
    [int]$Ignore=10, # Log only if number of event log entries are over this
    [string]$SourceFilter="ASP.NET", # e.g ASP.NET
    [string]$logFile
)

.\CheckEventLog.ps1 $LogName $EntryType $LastNMinutes $Ignore $SourceFilter $logFile