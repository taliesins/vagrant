Param(
)

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

$nfsCommand = Get-Command | ?{$_.Name -eq 'Get-NfsShare'}

if (!$nfsCommand) {
    $result = $false
} else {
    $nfsService = Get-Service | ?{$_.Name -eq 'NfsService'}

    if ($nfsService) {
        $result = $true
    } else {
        $result = $false
    }
}

$resultHash = @{
  supported = $result
}
$result = ConvertTo-Json $resultHash
Write-Output-Message $result