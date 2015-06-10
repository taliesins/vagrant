Param(
    [Parameter(Mandatory=$true)]
    [string]$environment,
    [Parameter(Mandatory=$true)]
    [string]$id,
    [Parameter(Mandatory=$true)]
    [string]$ips,
    [Parameter(Mandatory=$true)]
    [string]$folders
)

$ErrorAction = "Stop"

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

#Write-Error-Message "nfs_export -environment '$environment' -id '$id' -ips '$ips' -folders '$folders'"

try {
    if(!$ips) {
        Write-Error-Message "No ips specified"
    } else {
        $ips = $ips.Replace('\"', '""') | ConvertFrom-Json 
    }

    $hostIp = $ips[0]

    if (!$hostIp) {
        Write-Error-Message "No host ip specified"
    }

    if(!$folders) {
        Write-Error-Message "No folders specified"
    } else { 
        $shares = Get-NfsShare
        $sharesForVm = @()
        ($folders | ConvertFrom-Json) | Get-Member -MemberType NoteProperty | %{($folders | ConvertFrom-Json).$($_.Name) } | %{
            $folder = $_

            $name = $_.uuid
            $path = $_.hostpath
            if ($name -and $path)
            {
                $path = $path.Replace('/', '\')
                $share = $shares | ?{$path.Startswith($_.Path) -or $_.Path.Startswith($path) -or $_.Name -eq $name}
                if ($share){
                    if ($share.Name -eq $name -and $share.Path -eq $path){
                        Write-Host "Share with name='$name' for path='$path' already created"
                        $sharesForVm += @{name=$_.uuid; hostpath=$_.hostpath; guestpath="/$name"}
                    } elseif ($path.Startswith($share.Path)) {
                        Write-Host "Share with name='$name' for path='$path' is a subdirectory of share with name='$($share.Name)' with path='$($share.Path)'"
                        $subDirectory = $path.Substring($share.Path.length).Replace('\', '/')
                        $sharesForVm += @{name=$_.uuid; hostpath=$_.hostpath; guestpath="/$($share.Name)$subDirectory"}
                    } elseif ($share.Path.Startswith($path)) {
                        throw "Unable to create share with name='$name' and path='$path' as there is a subfolder with name='$($share.Name)' with path='$($share.Path)' that is already shared"
                    } else {
                        throw "Unable to create share with name='$name' and path='$path' as folder is already shared"

                        #Write-Host "Remove-NfsShare -Name '$name' -Confirm:`$false"
                        #Remove-NfsShare -Name $name -Confirm:$false
                        #Write-Host "New-NfsShare -Name '$name' -Path '$path' -AllowRootAccess `$true -EnableAnonymousAccess `$false -Permission Readwrite -Authentication all"
                        #New-NfsShare -Name $name -Path $path -AllowRootAccess $true -EnableAnonymousAccess $false -Permission Readwrite -Authentication all
                    }
                } else {
                    Write-Host "New-NfsShare -Name '$name' -Path '$path' -AllowRootAccess `$true -EnableAnonymousAccess `$false -Permission Readwrite -Authentication all"
                    $share = New-NfsShare -Name $name -Path $path -AllowRootAccess $true -EnableAnonymousAccess $false -Permission Readwrite -Authentication all
                    $sharesForVm += @{name=$_.uuid; hostpath=$_.hostpath; guestpath="/$name"}
                }
            } else {
                throw "Unable to create share with name='$name' and path='$path'"
            }
        }

        $resultHash = @{
          shares = $sharesForVm
        }
        $result = ConvertTo-Json $resultHash
        Write-Output-Message $result
    }
} catch {
    Write-Error-Message "Failed to create NFS shares. $_"
    return
}