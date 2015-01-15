param (
    [Parameter()]
    [ValidateRange(0, 2GB)]
    [int]
    $Last = 1000,

    [Parameter()]
    [int]
    $Minutes = 10,

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

$logpath = $env:windir + "\system32\LogFiles\HTTPERR\httperr*.log"

gi $logpath | % {

    # Find the position of the s-reason in the httperr log file
    $file = [System.io.File]::Open($_.FullName, 'Open', 'Read', 'ReadWrite')
    $reader = New-Object System.IO.StreamReader($file)
    try {
        $counter = 0
        $index = 0
        while ($line = $reader.ReadLine()) {
             $counter++
             if( $counter -gt 10 ) { break; }
             

            if($line.StartsWith("#Fields: ")) {
                $fieldNames = @($line.Substring("#Fields: ".Length).Split($Delimiter));
                $index = [array]::IndexOf($fieldNames, "s-reason");
                break;
            }
        }
    } finally {
        $reader.Close()
        $file.close();
    }

    $reasonCount = @{}
    # Parse the last N lines from last X minutes and count the number of reason
    .\GetLogContent.ps1 -Path $_.FullName -Last $Last -Minutes $Minutes -Newline $Newline | 
        % {
            $line = $_
            if ($line.StartsWith('#')) {
                # metadata
            }
            elseif ($line.Length -gt 0){
                $fieldValues = @($line.Split($Delimiter));
                $reason = $fieldValues[$index];

                if ($reasonCount.ContainsKey($reason)) {
                    $reasonCount[$reason]++;
                }
                else {
                    $reasonCount.Add($reason,1);
                }
            }
        }

    if ($OutputFile) {
        $reasonCount.GetEnumerator() | Sort-Object -Property Name -Descending |
            Select-Object -Property @{n='Library';e={$_.Name}},Value |
            Export-Csv -Path $OutputFile -NoTypeInformation
    } else {
        Write-Output $reasonCount
    }
}


