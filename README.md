# Project Tree

- pre-release for the mid july
- final build for july
- build for the html content issue in info reprot 0300

- release
- release in august
- release in september
- test (12/10/2026)
-fixes and test 
## Releases

CI creates a **new GitHub release for every build**, tagged `v<version>-build.<run number>` (e.g. `v1.2.3-build.57`), with `ENT_B1_Cockpit-Installer-<ver>.exe` attached.

> **Checksums are currently disabled.** The build no longer generates or packs checksum files, and `Install.bat` does not verify them.
> The scripts are kept for later use in `Electron_build_Scripts/utils/` (`New-Checksums.ps1`, `Verify-Checksums.ps1`), but nothing calls them.
