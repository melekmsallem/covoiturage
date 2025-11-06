# Fix ML Kit plugin namespaces in Pub cache
$commons = Join-Path $env:LOCALAPPDATA 'Pub/Cache/hosted/pub.dev/google_mlkit_commons-0.4.0/android/build.gradle'
if (Test-Path $commons) {
  if (-not (Select-String -Path $commons -Pattern 'namespace' -Quiet)) {
    @('', 'android {', '    namespace "com.google.mlkit.commons"', '}') | Add-Content -Path $commons
    Write-Host 'Added namespace to google_mlkit_commons'
  } else {
    Write-Host 'Namespace already present in google_mlkit_commons'
  }
} else {
  Write-Host 'google_mlkit_commons build.gradle not found' -ForegroundColor Yellow
}

$textrec = Join-Path $env:LOCALAPPDATA 'Pub/Cache/hosted/pub.dev/google_mlkit_text_recognition-0.8.1/android/build.gradle'
if (Test-Path $textrec) {
  if (-not (Select-String -Path $textrec -Pattern 'namespace' -Quiet)) {
    @('', 'android {', '    namespace "com.google.mlkit.textrecognition"', '}') | Add-Content -Path $textrec
    Write-Host 'Added namespace to google_mlkit_text_recognition'
  } else {
    Write-Host 'Namespace already present in google_mlkit_text_recognition'
  }
} else {
  Write-Host 'google_mlkit_text_recognition build.gradle not found' -ForegroundColor Yellow
}








