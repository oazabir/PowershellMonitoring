<#
.NOTES
  AUTHOR:       Keith Hill, r_keith_hill@hotmail.com
  DATE:         Jan 25, 2009
  NAME:         Tail-Content.ps1
  LICENSE:      BSD, http://en.wikipedia.org/wiki/BSD_license
  Copyright (c) 2009, Keith Hill
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

  * Redistributions of source code must retain the above copyright notice
    this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.
  * Neither the name of the COPYRIGHT HOLDERS nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
    A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
    OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
    LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
    THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
.LINK
  http://KeithHill.spaces.live.com
.SYNOPSIS
  Tail-Content efficiently displays the specified number of lines from
  the end of an ASCII file.
.DESCRIPTION
  Tail-Content efficiently displays the specified number of lines from
  the end of an ASCII file. When you use Get-Content foo.txt |
  Select-Object -Tail 5 every line in the foo.txt file is processed. This
  can be very inefficient and slow on large log files. Tail-Content uses
  stream processing to read the lines from the end of the file.
.PARAMETER LiteralPath
  Specifies the path to an item. Unlike Path, the value of LiteralPath is
  used exactly as typed. No characters are interpreted as wildcards. If
  the path includes escape characters, enclose it in single quotation
  marks. Single quotation marks tell Windows PowerShell not to interpret
  any characters as escape sequences.
.PARAMETER Path
  Specifies the path to an item. Get-Content retrieves the content of
  the item. Wildcards are permitted. The parameter name ("-Path" or
  "-FilePath") is optional.
.PARAMETER Last
  Specifies how many lines to get from the end of the file. The default
.PARAMETER Newline
  Specifies the default newline character sequence the default is
  [System.Environment]::Newline.
.EXAMPLE
  C:\PS>Tail-Content foo.txt

  Displays the last line of a file.  Note the last line of a file is
  quite often an empty line.
.EXAMPLE
  C:\PS>Tail-Content *.txt -Last 10

  Displays the last 10 lines of all .txt files in the current directory
.EXAMPLE
  C:\PS>Get-ChildItem . -inc *.log -r | tail-content -last 5

  Uses pipepline bound path parameter to determine path of file to tail
#>

#requires -version 2.0

[CmdletBinding(DefaultParameterSetName="Path")]
param(
    [Parameter(Mandatory=$true,
               Position=0,
               ParameterSetName="Path",
               ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $Path,

    [Alias("PSPath")]
    [Parameter(Mandatory=$true,
               Position=0,
               ParameterSetName="LiteralPath",
               ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $LiteralPath,

    [Parameter()]
    [switch]
    $Wait,

    [Parameter()]
    [ValidateRange(0, 2GB)]
    [int]
    $Last = 10,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]
    $Newline = $([Environment]::Newline)
)

Begin
{
  Set-StrictMode -Version 2.0
  $fs = $null
}

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

  if ($Wait -and ($resolvedPaths.Length -gt 1))
  {
    throw "Wait is only supported on one file at a time."
  }

  foreach ($rpath in $resolvedPaths)
  {
    $numLines = $Last
    $seekOffset = -1;
    $PathIntrinsics = $ExecutionContext.SessionState.Path

    if ($PathIntrinsics.IsProviderQualified($rpath))
    {
        $rpath = $PathIntrinsics.GetUnresolvedProviderPathFromPSPath($rpath)
    }

    Write-Verbose "Tail-Content processing $rpath"

    try
    {
      $output = New-Object "Text.StringBuilder"
      $newlineIndex = $Newline.Length - 1

      $fs = New-Object "IO.FileStream" $rpath,"Open","Read","ReadWrite"
      $oldLength = $fs.Length

      while ($numLines -gt 0 -and (($fs.Length + $seekOffset) -ge 0))
      {
      	[void]$fs.Seek($seekOffset--, "End")
      	$ch = $fs.ReadByte()

        if ($ch -eq 0 -or $ch -gt 127)
        {
            throw "Tail-Content only works on ASCII encoded files"
        }

        [void]$output.Insert(0, [char]$ch)

        # Count line terminations
      	if ($ch -eq $Newline[$newlineIndex])
        {
          if (--$newlineIndex -lt 0)
          {
            $newlineIndex = $Newline.Length - 1
            # Ignore the newline at the end of the file
            if ($seekOffset -lt -($Newline.Length + 1))
            {
              $numLines--
            }
          }
          continue
        }
      }

      # Remove beginning line terminator
      $output = $output.ToString().TrimStart([char[]]$Newline)
      Write-Output $output #-NoNewline

      if ($Wait)
      {
        # Now push pointer to end of file
        [void]$fs.Seek($oldLength, "Begin")

        for(;;)
        {
          if ($fs.Length -gt $oldLength)
          {
            $numNewBytes = $fs.Length - $oldLength
            $buffer = new-object byte[] $numNewBytes
            $numRead = $fs.Read($buffer, 0, $buffer.Length)

            $string = [Text.Encoding]::Ascii.GetString($buffer, 0,
              $buffer.Length)
            Write-Output $string # -NoNewline

            $oldLength += $numRead
          }
          Start-Sleep -Milliseconds 300
        }
      }
    }
    finally
    {
      if ($fs) { $fs.Close() }
    }
  }
}