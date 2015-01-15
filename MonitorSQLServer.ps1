param (    
    [string]$logFile
)

$serviceNames = "MSSQL`$SQLEXPRESS,SQLAgent`$SQLEXPRESS"

./MonitorServices.ps1 $serviceNames $logFile