<#
.SYNOPSIS
    Verifies files against a SHA-256 checksum manifest (sha256sum format).

.DESCRIPTION
    Each manifest line is "<64 hex chars> *<relative/path>" (or two spaces instead of "*").
    Blank lines and lines starting with "#" are ignored. Paths are resolved against -Root,
    which defaults to the folder containing the manifest.

    Files are hashed in parallel by a small compiled helper (Add-Type, built into Windows
    PowerShell). If compiling is not possible on the machine, a single-threaded PowerShell
    fallback is used (same result, slower).

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
    # Default (resolved below): checksums.sha256 next to this script.
    # Not set here: $PSScriptRoot is empty in param defaults under Windows PowerShell 5.1 with -File.
    [string]$ManifestPath,
    [string]$Root,
    # Number of files hashed in parallel (0 = automatic, based on CPU count)
    [int]$Threads = 0
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

# Status codes shared by the fast and fallback paths
$ST_OK = 0; $ST_MISSING = 1; $ST_MODIFIED = 2; $ST_UNREADABLE = 3

$VerifierSource = @'
using System;
using System.IO;
using System.Security.Cryptography;
using System.Threading;
using System.Threading.Tasks;

public static class B1ChecksumVerifier
{
    public static int Completed;

    // status[i]: 0 = OK, 1 = missing, 2 = modified, 3 = unreadable (message in errors[i])
    public static Task<int[]> Start(string[] paths, string[] hashes, string[] errors, int threads)
    {
        Completed = 0;
        return Task.Factory.StartNew(delegate
        {
            int[] status = new int[paths.Length];
            ParallelOptions options = new ParallelOptions();
            options.MaxDegreeOfParallelism = threads;
            Parallel.For(0, paths.Length, options,
                delegate { return SHA256.Create(); },
                delegate (int i, ParallelLoopState state, SHA256 sha)
                {
                    try
                    {
                        if (!File.Exists(paths[i]))
                        {
                            status[i] = 1;
                        }
                        else
                        {
                            using (FileStream fs = new FileStream(paths[i], FileMode.Open, FileAccess.Read,
                                                                  FileShare.Read, 1 << 16, FileOptions.SequentialScan))
                            {
                                status[i] = ToHex(sha.ComputeHash(fs)) == hashes[i] ? 0 : 2;
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        status[i] = 3;
                        errors[i] = ex.Message;
                    }
                    Interlocked.Increment(ref Completed);
                    return sha;
                },
                delegate (SHA256 sha) { sha.Dispose(); });
            return status;
        }, TaskCreationOptions.LongRunning);
    }

    static string ToHex(byte[] bytes)
    {
        char[] c = new char[bytes.Length * 2];
        for (int i = 0; i < bytes.Length; i++)
        {
            int b = bytes[i];
            c[i * 2] = "0123456789abcdef"[b >> 4];
            c[i * 2 + 1] = "0123456789abcdef"[b & 0xF];
        }
        return new string(c);
    }
}
'@

function Stop-WithManifestError([string]$Message) {
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    exit 2
}

try {
    if (-not $ManifestPath) {
        $scriptDir = $PSScriptRoot
        if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
        $ManifestPath = Join-Path $scriptDir 'checksums.sha256'
    }
    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        Stop-WithManifestError "Checksum manifest not found: $ManifestPath"
    }
    $ManifestPath = (Resolve-Path -LiteralPath $ManifestPath).ProviderPath
    if (-not $Root) { $Root = Split-Path -Parent $ManifestPath }
    $Root = (Resolve-Path -LiteralPath $Root).ProviderPath.TrimEnd('\')

    # --- Parse manifest -------------------------------------------------------
    $lineRx = New-Object System.Text.RegularExpressions.Regex '^([0-9A-Fa-f]{64}) [ *](.+)$'
    $unsafeRx = New-Object System.Text.RegularExpressions.Regex '(^|[\\/])\.\.([\\/]|$)'
    $relPaths = New-Object System.Collections.Generic.List[string]
    $fullPaths = New-Object System.Collections.Generic.List[string]
    $hashes = New-Object System.Collections.Generic.List[string]

    $lineNo = 0
    foreach ($line in [System.IO.File]::ReadAllLines($ManifestPath, [System.Text.Encoding]::UTF8)) {
        $lineNo++
        $line = $line.TrimEnd("`r")
        if ($line.Trim() -eq '' -or $line.TrimStart().StartsWith('#')) { continue }

        $m = $lineRx.Match($line)
        if (-not $m.Success) {
            Stop-WithManifestError ("Malformed line {0} in {1}" -f $lineNo, $ManifestPath)
        }
        $rel = $m.Groups[2].Value

        # Never let a manifest point outside the root folder.
        if ([System.IO.Path]::IsPathRooted($rel) -or $rel.Contains(':') -or $unsafeRx.IsMatch($rel)) {
            Stop-WithManifestError ("Unsafe path on line {0}: {1}" -f $lineNo, $rel)
        }
        $relPaths.Add($rel)
        $fullPaths.Add($Root + '\' + $rel.Replace('/', '\'))
        $hashes.Add($m.Groups[1].Value.ToLowerInvariant())
    }

    $total = $relPaths.Count
    if ($total -eq 0) {
        Stop-WithManifestError "Checksum manifest contains no entries: $ManifestPath"
    }

    # --- Verify ---------------------------------------------------------------
    if ($Threads -le 0) { $Threads = [Math]::Min(8, [Math]::Max(2, [Environment]::ProcessorCount)) }
    Write-Host "[INFO] Verifying $total file(s) against $(Split-Path -Leaf $ManifestPath) (SHA-256)..."
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    $errors = New-Object string[] $total
    $status = $null

    $fastPath = $true
    try {
        if (-not ('B1ChecksumVerifier' -as [type])) { Add-Type -TypeDefinition $VerifierSource -Language CSharp }
    } catch {
        $fastPath = $false
        Write-Host "[WARN] Parallel verifier unavailable ($($_.Exception.Message)); using slower fallback." -ForegroundColor Yellow
    }

    if ($fastPath) {
        $task = [B1ChecksumVerifier]::Start($fullPaths.ToArray(), $hashes.ToArray(), $errors, $Threads)
        while (-not $task.Wait(3000)) {
            Write-Host "[INFO]   ...$([B1ChecksumVerifier]::Completed) / $total"
        }
        $status = $task.Result
    } else {
        $status = New-Object int[] $total
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try {
            for ($i = 0; $i -lt $total; $i++) {
                $full = $fullPaths[$i]
                if (-not [System.IO.File]::Exists($full)) { $status[$i] = $ST_MISSING; continue }
                try {
                    $fs = [System.IO.File]::OpenRead($full)
                    try { $hex = ([System.BitConverter]::ToString($sha.ComputeHash($fs)) -replace '-', '').ToLowerInvariant() }
                    finally { $fs.Dispose() }
                    if ($hex -ne $hashes[$i]) { $status[$i] = $ST_MODIFIED }
                } catch {
                    $status[$i] = $ST_UNREADABLE
                    $errors[$i] = $_.Exception.Message
                }
                if (($i + 1) % 2000 -eq 0) { Write-Host "[INFO]   ...$($i + 1) / $total" }
            }
        } finally { $sha.Dispose() }
    }

    # --- Report ---------------------------------------------------------------
    $missing = New-Object System.Collections.Generic.List[string]
    $mismatch = New-Object System.Collections.Generic.List[string]
    $unreadable = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $total; $i++) {
        switch ($status[$i]) {
            $ST_MISSING    { $missing.Add($relPaths[$i]) }
            $ST_MODIFIED   { $mismatch.Add($relPaths[$i]) }
            $ST_UNREADABLE { $unreadable.Add("$($relPaths[$i]) ($($errors[$i]))") }
        }
    }

    $seconds = [Math]::Round($sw.Elapsed.TotalSeconds, 1)
    $failed = $missing.Count + $mismatch.Count + $unreadable.Count
    if ($failed -eq 0) {
        Write-Host "[OK] Integrity check passed: $total file(s) verified in $seconds s." -ForegroundColor Green
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
    Write-Host ("[ERROR] Integrity check FAILED: {0} of {1} file(s) did not verify." -f $failed, $total) -ForegroundColor Red
    exit 1
}
catch {
    Write-Host "[ERROR] Integrity check could not be completed: $($_.Exception.Message)" -ForegroundColor Red
    exit 2
}
