# Covoiturage Flutter App Launcher
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Covoiturage Flutter App Launcher" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if backend is running
Write-Host "Checking backend status..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8081/api/cities" -Method Get -TimeoutSec 2 -ErrorAction Stop
    Write-Host "✅ Backend is running on http://localhost:8081" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Backend not responding on http://localhost:8081" -ForegroundColor Red
    Write-Host "Please start the Spring Boot backend first!" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to continue anyway or Ctrl+C to exit"
}

Write-Host ""
Write-Host "Navigating to Flutter app directory..." -ForegroundColor Yellow
Set-Location -Path "covoiturage_app"

Write-Host ""
Write-Host "Installing Flutter dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Launching Flutter App on Chrome" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Available commands during run:" -ForegroundColor Yellow
Write-Host "  r - Hot reload" -ForegroundColor White
Write-Host "  R - Hot restart" -ForegroundColor White
Write-Host "  q - Quit" -ForegroundColor White
Write-Host ""
Write-Host "Backend API: http://localhost:8081/api" -ForegroundColor Cyan
Write-Host "Admin Dashboard: http://localhost:8081/admin-dashboard.html" -ForegroundColor Cyan
Write-Host ""

# Run Flutter app
flutter run -d chrome

Write-Host ""
Write-Host "Flutter app closed." -ForegroundColor Yellow


















