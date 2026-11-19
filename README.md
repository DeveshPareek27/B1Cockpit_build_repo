# Project Tree

- pre-release for the mid july
- final build for july
- build for the html content issue in info reprot 0300

- release
- release in august
- release in september
- test (12/10/2026)
-fixes and test 
## Build Integrity (SHA-256 checksums)

Every build produces three release files in `Electron_build_Scripts/`. CI creates a **new GitHub release for every build**, tagged `v<version>-build.<run number>` (e.g. `v1.2.3-build.57`), with the installer SHA-256 in the release notes and these files attached:

| File | Purpose |
|------|---------|
| `ENT_B1_Cockpit-Installer-<ver>.exe` | The installer (7-Zip SFX) |
| `ENT_B1_Cockpit-Installer-<ver>.exe.sha256` | SHA-256 of the installer, `sha256sum` format; used to verify the download |
| `ENT_B1_Cockpit-Installer-<ver>.json` | Release metadata (version, size, SHA-256, payload manifest hash); used by the in-app upgrade check |

There are two layers of verification:

1. **Download check (user / support).** After downloading, compare the installer hash with the published `.sha256` value:
   ```powershell
   Get-FileHash .\ENT_B1_Cockpit-Installer-<ver>.exe -Algorithm SHA256
   # or: certutil -hashfile ENT_B1_Cockpit-Installer-<ver>.exe SHA256
   ```
2. **Install check (automatic).** The installer contains `checksums.sha256`, which lists the SHA-256 of every packed file. `Install.bat` runs `Verify-Checksums.ps1` first and **aborts the installation** if any file is missing or modified.

Scripts (in `Electron_build_Scripts/utils/`):
- `New-Checksums.ps1`: build time; generates the payload manifest and the installer `.sha256`/`.json` files (called from `createBuild.bat` and `5_create_ZIP.bat`).
- `Verify-Checksums.ps1`: shipped in the installer; verifies any `sha256sum`-format file (exit 0 = OK, 1 = mismatch, 2 = manifest error). It can verify a download too:
  `powershell -ExecutionPolicy Bypass -File Verify-Checksums.ps1 -ManifestPath .\ENT_B1_Cockpit-Installer-<ver>.exe.sha256`

> When adding files to the installer, add them to **both** the `New-Checksums.ps1` call and the `7z a` call, or `Install.bat` will reject the package.
