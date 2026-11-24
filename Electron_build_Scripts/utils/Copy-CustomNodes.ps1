<#
.SYNOPSIS
    Copies only the ENT_RED_CustomNodes folders that the app actually depends on.

.DESCRIPTION
    Reads the "dependencies" of the given package.json and picks every entry of the form
        "file:API/ENT_RED_CustomNodes/<folder>"
    Only those folders are copied from -Source to -Destination, so unused nodes
    (ENT_App_Common, GoogleApi-*, metadata-engine, install_*.bat, ...) never reach
    the build and are not packed into app.asar.

    To ship an additional custom node, just add it as a "file:" dependency in
    electron_files\package-template.json - no change to this script is needed.

    node_modules and .git folders are skipped; "npm install" re-creates node_modules.

.EXAMPLE
    Copy-CustomNodes.ps1 -PackageJson electron_files\package-template.json `
                         -Source D:\repo\ENT_RED_CustomNodes `
                         -Destination D:\build\API\ENT_RED_CustomNodes
#>
param(
    [Parameter(Mandatory = $true)][string]$PackageJson,
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Destination
)

$ErrorActionPreference = 'Stop'
$prefix = 'file:API/ENT_RED_CustomNodes/'

if (-not (Test-Path -LiteralPath $PackageJson -PathType Leaf)) {
    Write-Host "[ERROR] package.json not found: $PackageJson"
    exit 1
}

$pkg = Get-Content -Raw -LiteralPath $PackageJson | ConvertFrom-Json

$folders = @(
    $pkg.dependencies.PSObject.Properties |
        Where-Object { $_.Value -like "$prefix*" } |
        ForEach-Object { $_.Value.Substring($prefix.Length).Trim('/').Replace('/', '\') } |
        Sort-Object -Unique
)

if ($folders.Count -eq 0) {
    Write-Host "[ERROR] No '$prefix*' dependencies found in $PackageJson"
    exit 1
}

$missing = @($folders | Where-Object { -not (Test-Path -LiteralPath (Join-Path $Source $_) -PathType Container) })
if ($missing.Count -gt 0) {
    Write-Host "[ERROR] Custom node folder(s) referenced in package.json but missing in ${Source}:"
    $missing | ForEach-Object { Write-Host "          - $_" }
    exit 1
}

Write-Host "[INFO] Copying $($folders.Count) custom node(s) to $Destination"
foreach ($folder in $folders) {
    $src = Join-Path $Source $folder
    $dst = Join-Path $Destination $folder
    Write-Host "[INFO]   - $folder"

    robocopy $src $dst /E /XD node_modules .git /NFL /NDL /NJH /NJS /NP | Out-Null
    # robocopy: 0-7 = success (files copied / nothing to copy / extras), 8+ = failure
    if ($LASTEXITCODE -ge 8) {
        Write-Host "[ERROR] robocopy failed for '$folder' (exit code $LASTEXITCODE)"
        exit 1
    }
}

exit 0
