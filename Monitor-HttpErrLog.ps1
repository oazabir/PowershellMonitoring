param (
    [Parameter()]
    [ValidateRange(0, 2GB)]
    [int]
    $Last = 1000,

    [Parameter()]
    [int]
    $Minutes = 1440,

    [ValidateNotNullOrEmpty()]
    [string]
    $Delimiter = " ",
    
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]
    $Newline = $([Environment]::Newline),

    [Parameter()]
    [string]
    $OutputFile
)
$threshold = @{
"AppOffline"=0; # A service unavailable error occurred (an HTTP error 503). The service is not available because application errors caused the application to be taken offline.
"AppPoolTimer"=0; # A service unavailable error occurred (an HTTP error 503). The service is not available because the application pool process is too busy to handle the request.
"AppShutdown"=0; #  A service unavailable error occurred (an HTTP error 503). The service is not available because the application shut down automatically in response to administrator policy.
"Bad Request"=100; # A parse error occurred while processing a request.
"Client_Reset"=100; # The connection between the client and the server was closed before the request could be assigned to a worker process. The most common cause of this behavior is that the client prematurely closes its connection to the server.
"Connection_Abandoned_By_AppPool"=10; # A worker process from the application pool has quit unexpectedly or orphaned a pending request by closing its handle.
"Connection_Abandoned_By_ReqQueue"=10; # A worker process from the application pool has quit unexpectedly or orphaned a pending request by closing its handle. Specific to Windows Vista and Windows Server 2008.
"Connection_Dropped"=100; # The connection between the client and the server was closed before the server could send its final response packet. The most common cause of this behavior is that the client prematurely closes its connection to the server.
"ConnLimit"=0; # A service unavailable error occurred (an HTTP error 503). The service is not available because the site level connection limit has been reached or exceeded.
"Connections_Refused"=0; # The kernel NonPagedPool memory has dropped below 20MB and http.sys has stopped receiving new connections.
"Disabled"=100; # A service unavailable error occurred (an HTTP error 503). The service is not available because an administrator has taken the application offline.
"EntityTooLarge"=100; # An entity exceeded the maximum size that is permitted.
"FieldLength"=100; # A field length limit was exceeded.
"Forbidden"=100; # A forbidden element or sequence was encountered while parsing.
"Header"=100; # A parse error occurred in a header.
"Hostname"=100; # A parse error occurred while processing a Hostname.
"Internal"=10; # An internal server error occurred (an HTTP error 500).
"Invalid_CR/LF"=100; # An illegal carriage return or line feed occurred.
"N/A"=1; # A service unavailable error occurred (an HTTP error 503). The service is not available because an internal error (such as a memory allocation failure) occurred.
"N/I"=1; # A not-implemented error occurred (an HTTP error 501), or a service unavailable error occurred (an HTTP error 503) because of an unknown transfer encoding.
"Number"=100; # A parse error occurred while processing a number.
"Precondition"=0; # A required precondition was missing.
"QueueFull"=0; # A service unavailable error occurred (an HTTP error 503). The service is not available because the application request queue is full.
"RequestLength"=100; # A request length limit was exceeded.
"Timer_AppPool"=10; # The connection expired because a request waited too long in an application pool queue for a server application to de queue and process it. This timeout duration is ConnectionTimeout. By default, this value is set to two minutes.
"Timer_Connection Idle"=100; # The connection expired and remains idle. The default ConnectionTimeout duration is two minutes.
"Timer_EntityBody"=10; # The connection expired before the request entity body arrived. When it is clear that a request has an entity body, the HTTP API turns on the Timer_EntityBody timer. Initially, the limit of this timer is set to the ConnectionTimeout value (typically 2 minutes). Each time another data indication is received on this request, the HTTP API resets the timer to give the connection two more minutes (or whatever is specified in ConnectionTimeout).
"Timer_HeaderWait"=10; # The connection expired because the header parsing for a request took more time than the default limit of two minutes.
"Timer_MinBytesPerSecond"=10; # The connection expired because the client was not receiving a response at a reasonable speed. The response send rate was slower than the default of 240 bytes/sec. This can be controlled with the MinFileBytesPerSec metabase property.
"Timer_ReqQueue"=10; # The connection expired because a request waited too long in an application pool queue for a server application to dequeue. This timeout duration is ConnectionTimeout. By default, this value is set to two minutes. Specific to Windows Vista and Windows Server 2008.
"Timer_Response"=0; # Reserved. Not currently used.
"URL"=100; # A parse error occurred while processing a URL.
"URL_Length"=100; # A URL exceeded the maximum permitted size.
"Verb"=100; # A parse error occurred while processing a verb.
"Version_N/S"=0 # : A version-not-supported error occurred (an HTTP error 505).
};

$reasonCount = .\Count-HttpErrReason.ps1 -Last $Last -Minutes $Minutes -Delimiter $Delimiter -Newline $Newline -outputFile $OutputFile

switch ($reasonCount.GetEnumerator())
{ 
    {$threshold.ContainsKey($_.Key) -and $_.Value -gt $threshold[$_.Key]} {"ERROR: $($_.Key) is more than $($threshold[$_.Key])"}
}
