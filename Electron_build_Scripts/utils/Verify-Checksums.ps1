<#
.SYNOPSIS
    Verifies files against a SHA-256 checksum manifest (sha256sum format).

.DESCRIPTION
    Each manifest line is "<64 hex chars> *<relative/path>" (or two spaces instead of "*").
    Blank lines and lines starting with "#" are ignored. Paths are resolved against -Root,
    which defaults to the folder containing the manifest.

    Exit codes:
        0  all files present and matching
        1  one or more files missing, unreadable or modified
        2  manifest missing/invalid or unexpected error

.EXAMPLE
    # Verify the extracted installer contents (Install.bat does this automatically)
    powershell -NoProfile -ExecutionPolicy Bypass -File Verify-Checksums.ps1

.EXAMPLE
    # Verify a downloaded installer against its published .sha256 file
    powershell -NoProfile -ExecutionPolicy Bypass -File Verify-Checksums.ps1 -ManifestPath .\ENT_B1_Cockpit-Installer-1.2.3.exe.sha256
#>
[CmdletBinding()]
param(
    [string]$ManifestPath = (Join-Path $PSScriptRoot 'checksums.sha256'),
    [string]$Root
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

function Stop-WithManifestError([string]$Message) {
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    exit 2
}

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
    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        Stop-WithManifestError "Checksum manifest not found: $ManifestPath"
    }
    $ManifestPath = (Resolve-Path -LiteralPath $ManifestPath).ProviderPath
    if (-not $Root) { $Root = Split-Path -Parent $ManifestPath }
    $Root = (Resolve-Path -LiteralPath $Root).ProviderPath.TrimEnd('\')

    # --- Parse manifest -------------------------------------------------------
    $entries = New-Object System.Collections.Generic.List[object]
    $lineNo = 0
    foreach ($line in [System.IO.File]::ReadAllLines($ManifestPath, [System.Text.Encoding]::UTF8)) {
        $lineNo++
        $line = $line.TrimEnd("`r")
        if ($line.Trim() -eq '' -or $line.TrimStart().StartsWith('#')) { continue }

        if ($line -notmatch '^([0-9A-Fa-f]{64}) [ *](.+)$') {
            Stop-WithManifestError ("Malformed line {0} in {1}" -f $lineNo, $ManifestPath)
        }
        $expected = $Matches[1].ToLowerInvariant()
        $rel = $Matches[2]

        # Never let a manifest point outside the root folder.
        if ([System.IO.Path]::IsPathRooted($rel) -or $rel.Contains(':') -or $rel -match '(^|[\\/])\.\.([\\/]|$)') {
            Stop-WithManifestError ("Unsafe path on line {0}: {1}" -f $lineNo, $rel)
        }
        $entries.Add([pscustomobject]@{ Hash = $expected; RelPath = $rel })
    }

    if ($entries.Count -eq 0) {
        Stop-WithManifestError "Checksum manifest contains no entries: $ManifestPath"
    }

    # --- Verify ---------------------------------------------------------------
    Write-Host "[INFO] Verifying $($entries.Count) file(s) against $(Split-Path -Leaf $ManifestPath) (SHA-256)..."

    $missing = New-Object System.Collections.Generic.List[string]
    $mismatch = New-Object System.Collections.Generic.List[string]
    $unreadable = New-Object System.Collections.Generic.List[string]
    $done = 0

    foreach ($e in $entries) {
        $full = Join-Path $Root ($e.RelPath.Replace('/', '\'))
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
            $missing.Add($e.RelPath)
        } else {
            try {
                if ((Get-Sha256 $full) -ne $e.Hash) { $mismatch.Add($e.RelPath) }
            } catch {
                $unreadable.Add("$($e.RelPath) ($($_.Exception.Message))")
            }
        }
        $done++
        if ($done % 1000 -eq 0) { Write-Host "[INFO]   ...$done / $($entries.Count)" }
    }

    $failed = $missing.Count + $mismatch.Count + $unreadable.Count
    if ($failed -eq 0) {
        Write-Host "[OK] Integrity check passed: $($entries.Count) file(s) verified." -ForegroundColor Green
        exit 0
    }

    $maxShown = 20
    foreach ($group in @(
            @{ Label = 'MISSING';    Items = $missing },
            @{ Label = 'MODIFIED';   Items = $mismatch },
            @{ Label = 'UNREADABLE'; Items = $unreadable })) {
        if ($group.Items.Count -eq 0) { continue }
        Write-Host ("[ERROR] {0} ({1}):" -f $group.Label, $group.Items.Count) -ForegroundColor Red
        $group.Items | Select-Object -First $maxShown | ForEach-Object { Write-Host "          $_" -ForegroundColor Red }
        if ($group.Items.Count -gt $maxShown) { Write-Host "          ... and $($group.Items.Count - $maxShown) more" -ForegroundColor Red }
    }
    Write-Host ("[ERROR] Integrity check FAILED: {0} of {1} file(s) did not verify." -f $failed, $entries.Count) -ForegroundColor Red
    exit 1
}
catch {
    Write-Host "[ERROR] Integrity check could not be completed: $($_.Exception.Message)" -ForegroundColor Red
    exit 2
}
