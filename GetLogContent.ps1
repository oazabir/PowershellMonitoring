[CmdletBinding(DefaultParameterSetName="Path")]
param (
    [Parameter(Mandatory=$true,
               Position=0,
               ParameterSetName="Path",
               ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]    
    $Path,

    [Parameter()]
    [ValidateRange(0, 2GB)]
    [int]
    $Last = 1000,

    [Parameter()]
    [int]
    $Minutes = 10,
    
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]
    $Newline = $([Environment]::Newline)
)

Process
{
  if ($psCmdlet.ParameterSetName -eq "Path")
  {
    # In the non-literal case we may need to resolve a wildcarded path
    $resolvedPaths = @()
    foreach ($apath in $Path)
    {
        $resolvedPaths += @(Resolve-Path $apath | Foreach { $_.Path })
    }
  }
  else
  {
    $resolvedPaths = $LiteralPath
  }

  $date = [DateTime]::Now.AddMinutes(-$Minutes)

  foreach ($rpath in $resolvedPaths)
  {
    if ($Minutes -eq 0) {
        $lines = (.\Tail-Content.ps1 $rpath -Last $Last -Newline $Newline)
        $lines = $output.Split($Newline)
        $lines | Write-Output
    }
    else {
        $output = (.\Tail-Content.ps1 $rpath -Last $Last -Newline $Newline) 
        $lines = $output.Split($Newline)
        $lines | % {             
                if (($_ -match "^(\d+\-\d+\-\d+\s+\d+:\d+:\d+)")) {
                    $datepart = $_.Substring(0, $_.indexOf(' ', 12));
                    $logdate = [DateTime]::Parse($datepart)
                    $diff = $logdate - $date
                
                    if ( $diff.TotalSeconds -gt 0) {
                        Write-Output $_
                    }
                }
            }
    }
         
  }
}


#C:\windows\system32\LogFiles\HTTPERR\*
#select-string -Pattern "\d-\d-\d\s-\d:\d:\d\s" | 