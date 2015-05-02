Param(
    [Parameter(Mandatory=$true)]
    [string]$VmId
 )

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

$vm = Get-VM -Id $VmId -ErrorAction "Stop"
$networks = Get-VMNetworkAdapter -VM $vm

$results = @()

$networks | %{
    $_.IpAddresses | %{
        $results += $_
    }
}

$result = ConvertTo-Json $results
Write-Output-Message $result