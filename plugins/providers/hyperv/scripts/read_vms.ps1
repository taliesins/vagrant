Param(
)

$ErrorAction = "Stop"

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

$vmIds = get-vm | %{$_.Id}

$result = @{
	values = $vmIds
}

Write-Output-Message (ConvertTo-Json $result)