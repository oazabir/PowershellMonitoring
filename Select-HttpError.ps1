# Credit: http://poshcode.org/2574
param
(
	[Parameter(
		Mandatory=$true,
		Position = 0,
		ValueFromPipeline=$true,
		HelpMessage="Specifies the path to the IIS *.log file to import. You can also pipe a path to Import-Iss-Log."
	)]
	[ValidateNotNullOrEmpty()]
	[string]
	$Path,
	
	[Parameter(
		Position = 1,
		HelpMessage="Specifies the delimiter that separates the property values in the IIS *.log file. The default is a spacebar."
	)]
	[ValidateNotNullOrEmpty()]
	[string]
	$Delimiter = " ",
	
	[Parameter(HelpMessage="The character encoding for the IIS *log file. The default is the UTF8.")]
	[Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]
	$Encoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::UTF8
)
	
begin
{
	$fieldNames = @()
	
	$output = New-Object Object
	Add-Member -InputObject $output -MemberType NoteProperty -Name "DateTime" -Value $null
	Add-Member -InputObject $output -MemberType NoteProperty -Name "ClientHost" -Value $null
	Add-Member -InputObject $output -MemberType NoteProperty -Name "UserName" -Value $null
	Add-Member -InputObject $output -MemberType NoteProperty -Name "Service" -Value $null
	Add-Member -InputObject $output -MemberType NoteProperty -Name "Machine" -Value $null
	Add-Member -InputObject $output -MemberType NoteProperty -Name "ServerIp" -Value $null
	Add-Member -InputObject $output -MemberType NoteProperty -Name "ServerPort" -Value $null
	Add-Member -InputObject $output -MemberType NoteProperty -Name "Method" -Value $null
	Add-Member -InputObject $output -MemberType NoteProperty -Name "ScriptPath" -Value $null
	Add-Member -InputObject $output -MemberType NoteProperty -Name "QueryString" -Value $null
	Add-Member -InputObject $output -MemberType NoteProperty -Name "ServiceStatus" -Value $null
	Add-Member -InputObject $output -MemberType NoteProperty -Name "ServiceSubStatus" -Value $null
	Add-Member -InputObject $output -MemberType NoteProperty -Name "Win32Status" -Value $null
	Add-Member -InputObject $output -MemberType NoteProperty -Name "BytesSent" -Value $null
	Add-Member -InputObject $output -MemberType NoteProperty -Name "BytesRecived" -Value $null
	Add-Member -InputObject $output -MemberType NoteProperty -Name "ProcessingTime" -Value $null
	Add-Member -InputObject $output -MemberType NoteProperty -Name "ProtocolVersion" -Value $null
	Add-Member -InputObject $output -MemberType NoteProperty -Name "Host" -Value $null
	Add-Member -InputObject $output -MemberType NoteProperty -Name "UserAgent" -Value $null
	Add-Member -InputObject $output -MemberType NoteProperty -Name "Cookie" -Value $null
	Add-Member -InputObject $output -MemberType NoteProperty -Name "Referer" -Value $null
}

process
{
	foreach($line in Get-Content -Path $Path -Encoding $Encoding)
	{
		if($line.StartsWith("#Fields: "))
		{
			$fieldNames = @($line.Substring("#Fields: ".Length).Split($Delimiter));
		}
		elseif(-not $line.StartsWith("#"))
		{
			$fieldValues = @($line.Split($Delimiter));
			
			for($i = 0; $i -lt $fieldValues.Length; $i++)
			{
				$name = $fieldNames[$i]
				$value = $fieldValues[$i]
				
				switch($name)
				{
				"date" { $output.DateTime = [DateTime]::Parse($value) }
				"time" { $output.DateTime += [TimeSpan]::Parse($value) }
				"c-ip" { $output.ClientHost = [System.Net.IPAddress]::Parse($value) }
				"cs-username" { $output.UserName = if($value -eq '-') { $null } else { $value } }
				"s-sitename" { $output.Service = $value }
				"s-computername" { $output.Machine = $value }
				"s-ip" { $output.ServerIp = [System.Net.IPAddress]::Parse($value) }
				"s-port" { $output.ServerPort = [int]$value }
				"cs-method" { $output.Method = $value }
				"cs-uri-stem" { $output.ScriptPath = [System.Web.HttpUtility]::UrlDecode($value) }
				"cs-uri-query" { $output.QueryString = if($value -eq '-') { $null } else { [System.Web.HttpUtility]::UrlDecode($value) } }
				"sc-status" { $output.ServiceStatus = [int]$value }
				"sc-substatus" { $output.ServiceSubStatus = [int]$value }
				"sc-win32-status" { $output.Win32Status = [BitConverter]::ToInt32([BitConverter]::GetBytes([UInt32]($value)), 0) }
				"sc-bytes" { $output.BytesSent = [UInt64]$value }
				"cs-bytes" { $output.BytesRecived = [UInt64]$value }
				"time-taken" { $output.ProcessingTime = [int]$value }
				"cs-version" { $output.ProtocolVersion = $value }
				"cs-host" { $output.Host = if($value -eq '-') { $null } else { $value } }
				"cs(User-Agent)" { $output.UserAgent = if($value -eq '-') { $null } else { $value } }
				"cs(Cookie)" { $output.Cookie = if($value -eq '-') { $null } else { $value } }
				"cs(Referer)" { $output.Referer = if($value -eq '-') { $null } else { [System.Web.HttpUtility]::UrlDecode($value) } }
				}
			}
			
			Write-Output $output
		}
	}
}