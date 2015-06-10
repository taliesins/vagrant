Param(
    [Parameter(Mandatory=$true)]
    [string]$environment,
    [Parameter(Mandatory=$true)]
    [string]$valid_ids
)

$ErrorAction = "Stop"

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

#Write-Error-Message "nfs_prune -environment '$environment' -valid_ids '$valid_ids'"

try {
    if(!$valid_ids) {
        Write-Error-Message "No valid ids specified"
    } else {
        $valid_ids = $valid_ids.Replace('\"', '""') | ConvertFrom-Json
    }
} catch {
    Write-Error-Message "Failed to prune NFS shares. $_"
    return
}