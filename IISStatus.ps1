param (    
    [string]$logFile
)

$serviceNames = "W3SVC,WAS,RpcSs,DcomLaunch"

./MonitorServices.ps1 $serviceNames $logFile