Param(
)

$ErrorAction = "Stop"

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

$ipAddresses = Get-NetIPAddress | Where-Object {($_.IPAddress -ne "127.0.0.1") -and ($_.IPAddress -ne "::1") -and (!$_.IPAddress.StartsWith("169.254."))} | Sort-Object -Property AddressFamily, InterfaceIndex | %{ ($_.IpAddress -split '%')[0]}

$result = @{
	ip_addresses = $ipAddresses
}

Write-Output-Message (ConvertTo-Json $result)