<#
.SYNOPSIS
    Build-time SHA-256 checksum generation for the ENT_B1_Cockpit installer.

.DESCRIPTION
    Payload mode (-OutFile + paths):
        Writes a sha256sum-compatible manifest ("<hash> *<relative/path>") covering every
        file that is packed into the installer. Paths are relative to the archive root,
        exactly as 7-Zip stores them: a directory is stored under its own folder name,
        a single file under its file name. The manifest is shipped inside the installer
        and checked by Install.bat (via Verify-Checksums.ps1) before installation.

    Release mode (-Installer):
        Hashes the finished installer and writes, next to it:
            <installer>.sha256  "<hash> *<installer file name>"  -> verify the download
            <installer>.json    release metadata                 -> used by upgrade checks

.EXAMPLE
    New-Checksums.ps1 -OutFile C:\out\checksums.sha256 C:\build\App-win32-x64 C:\utils\Install.bat

.EXAMPLE
    New-Checksums.ps1 -Installer C:\out\App-Installer-1.2.3.exe -Product App -Version 1.2.3 -PayloadManifest C:\out\checksums.sha256
#>
[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Payload')]
    [string]$OutFile,

    [Parameter(Mandatory = $true, ParameterSetName = 'Payload', ValueFromRemainingArguments = $true)]
    [string[]]$Path,

    [Parameter(Mandatory = $true, ParameterSetName = 'Release')]
    [string]$Installer,

    [Parameter(Mandatory = $true, ParameterSetName = 'Release')]
    [string]$Product,

    [Parameter(Mandatory = $true, ParameterSetName = 'Release')]
    [string]$Version,

    [Parameter(ParameterSetName = 'Release')]
    [string]$PayloadManifest
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Get-Sha256([string]$FilePath) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $stream = [System.IO.File]::OpenRead($FilePath)
    try {
        return ([System.BitConverter]::ToString($sha.ComputeHash($stream)) -replace '-', '').ToLowerInvariant()
    } finally {
        $stream.Dispose()
        $sha.Dispose()
    }
}

try {
    if ($PSCmdlet.ParameterSetName -eq 'Payload') {
        $entries = New-Object System.Collections.Generic.List[string]
        $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

        foreach ($p in $Path) {
            $item = Get-Item -LiteralPath $p -Force
            if ($item.PSIsContainer) {
                $base = $item.FullName.TrimEnd('\')
                $files = @(Get-ChildItem -LiteralPath $base -Recurse -File -Force | Sort-Object FullName)
                Write-Host "[INFO] Hashing $($files.Count) files in $($item.Name)..."
                foreach ($f in $files) {
                    $rel = $item.Name + '/' + $f.FullName.Substring($base.Length + 1).Replace('\', '/')
                    if (-not $seen.Add($rel)) { throw "Duplicate archive path: $rel" }
                    $entries.Add((Get-Sha256 $f.FullName) + ' *' + $rel)
                }
            } else {
                if (-not $seen.Add($item.Name)) { throw "Duplicate archive path: $($item.Name)" }
                $entries.Add((Get-Sha256 $item.FullName) + ' *' + $item.Name)
            }
        }

        if ($entries.Count -eq 0) { throw 'No files found to hash.' }

        # LF line endings keep the file usable with GNU "sha256sum -c" as well.
        [System.IO.File]::WriteAllText($OutFile, (($entries -join "`n") + "`n"), $Utf8NoBom)
        Write-Host "[INFO] Payload manifest written: $OutFile ($($entries.Count) files)"
    }
    else {
        $inst = Get-Item -LiteralPath $Installer
        $hash = Get-Sha256 $inst.FullName

        $shaFile = $inst.FullName + '.sha256'
        [System.IO.File]::WriteAllText($shaFile, "$hash *$($inst.Name)`n", $Utf8NoBom)

        $meta = [ordered]@{
            product       = $Product
            version       = $Version
            buildDate     = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
            hashAlgorithm = 'SHA-256'
            installer     = [ordered]@{
                fileName = $inst.Name
                size     = $inst.Length
                sha256   = $hash
            }
        }
        if ($env:GITHUB_SHA) { $meta.commit = $env:GITHUB_SHA }

        if ($PayloadManifest) {
            $pm = Get-Item -LiteralPath $PayloadManifest
            $count = @([System.IO.File]::ReadAllLines($pm.FullName) | Where-Object { $_.Trim() -ne '' }).Count
            $meta.payloadManifest = [ordered]@{
                fileName  = $pm.Name
                sha256    = (Get-Sha256 $pm.FullName)
                fileCount = $count
            }
        }

        $jsonFile = [System.IO.Path]::ChangeExtension($inst.FullName, '.json')
        [System.IO.File]::WriteAllText($jsonFile, (ConvertTo-Json -InputObject $meta -Depth 5), $Utf8NoBom)

        Write-Host "[INFO] Installer SHA-256: $hash"
        Write-Host "[INFO] Checksum file:     $shaFile"
        Write-Host "[INFO] Release manifest:  $jsonFile"
    }
    exit 0
}
catch {
    Write-Host "[ERROR] Checksum generation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
