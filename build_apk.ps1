param(
    [ValidateSet("debug", "release", "both")]
    [string]$Type = "debug"
)

$projectDir = "C:\Users\shrey\Desktop\MCA_OC\gokulam_app"

Write-Host "`n=== Gokulam Traders APK Builder ===" -ForegroundColor Cyan
Write-Host "Building $Type APK..." -ForegroundColor Yellow

Set-Location -LiteralPath $projectDir

switch ($Type) {
    "debug" {
        flutter build apk --debug
    }
    "release" {
        flutter build apk --release
    }
    "both" {
        flutter build apk --debug
        Write-Host "`nDebug APK built, now building release..." -ForegroundColor Yellow
        flutter build apk --release
    }
}

if ($?) {
    $apkDir = "$projectDir\build\app\outputs\flutter-apk"
    Write-Host "`n✅ APK built successfully!" -ForegroundColor Green
    Write-Host "Location: $apkDir" -ForegroundColor Green
    Get-ChildItem -Path $apkDir -Filter "*.apk" | ForEach-Object {
        Write-Host "  - $($_.Name) ($([math]::Round($_.Length/1MB, 2)) MB)" -ForegroundColor Cyan
    }
} else {
    Write-Host "❌ Build failed. Check errors above." -ForegroundColor Red
}
