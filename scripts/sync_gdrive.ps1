# PowerShell script to sync release artifacts to Google Drive and local gdrive folder
$appName = "Nested App"
$projectRoot = Split-Path -Parent $PSScriptRoot

$gdriveRoot = Join-Path $env:USERPROFILE "Google Drive"
$targetGdriveDir = Join-Path $gdriveRoot $appName
$localGdriveDir = Join-Path $projectRoot "gdrive\$appName"
$syncTargets = @($targetGdriveDir, $localGdriveDir)

$artifacts = @(
    @{
        Source = Join-Path $projectRoot "Nested-TaskStrategy-v2.1.8-review.apk"
        DestName = "Nested-v2.1.8-Build13.apk"
        Description = "Release APK (v2.1.8+13 Build 13)"
    },
    @{
        Source = Join-Path $projectRoot "Nested-TaskStrategy-v2.1.8-review.apk"
        DestName = "Nested-v2.1.8.apk"
        Description = "Latest Release APK (v2.1.8+13)"
    },
    @{
        Source = Join-Path $projectRoot "release-v2.1.8\app-release-v2.1.8.apk"
        DestName = "Nested-v2.1.8-Build12.apk"
        Description = "Previous Build APK (v2.1.8+12 Build 12)"
    },
    @{
        Source = Join-Path $projectRoot "release-v2.1.7\app-release-updated.apk"
        DestName = "Nested-v2.1.7.apk"
        Description = "Previous Release APK (v2.1.7+10 Build 10)"
    },
    @{
        Source = Join-Path $projectRoot "release-v2.1.7\native-debug-symbols.zip"
        DestName = "native-debug-symbols-v2.1.7.zip"
        Description = "Native Debug Symbols (v2.1.7)"
    }
)

foreach ($art in $artifacts) {
    if (Test-Path $art.Source) {
        $sizeMb = [math]::Round(((Get-Item $art.Source).Length / 1MB), 2)
        Write-Host "`n[+] Syncing: $($art.Description) ($($art.DestName), $sizeMb MB)" -ForegroundColor Green
        foreach ($target in $syncTargets) {
            $destPath = Join-Path $target $art.DestName
            Copy-Item -Path $art.Source -Destination $destPath -Force
            Write-Host "    --> $destPath" -ForegroundColor Gray
        }
    } else {
        Write-Host "[-] Missing source: $($art.Source)" -ForegroundColor Yellow
    }
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "  SYNC COMPLETED SUCCESSFULLY!" -ForegroundColor Cyan
Write-Host "  Google Drive: $targetGdriveDir" -ForegroundColor White
Write-Host "  Local Mirror: $localGdriveDir" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan
