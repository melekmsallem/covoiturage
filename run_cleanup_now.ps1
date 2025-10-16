# Simple Cleanup Executor
Write-Host "🧹 Deleting Old Trips..." -ForegroundColor Cyan

# Login and run cleanup in one go
$loginData = '{"usernameOrEmail":"admin","password":"admin123"}'
$authResponse = Invoke-RestMethod -Uri "http://localhost:8081/api/auth/signin" `
    -Method Post -Body $loginData -ContentType "application/json"

$headers = @{ 
    Authorization = "Bearer $($authResponse.token)"
    "Content-Type" = "application/json"
}

Write-Host "✅ Logged in as admin" -ForegroundColor Green

# Run cleanup
try {
    $result = Invoke-RestMethod -Uri "http://localhost:8081/api/admin/maintenance/cleanup?dryRun=false" `
        -Method Post -Headers $headers
    
    Write-Host "`n✅ CLEANUP COMPLETED!" -ForegroundColor Green
    Write-Host "`nDeleted:" -ForegroundColor Yellow
    Write-Host "  - Trips: $($result.deletedVoyages)" -ForegroundColor White
    Write-Host "  - Reservations: $($result.deletedReservations)" -ForegroundColor White
    Write-Host "  - Cutoff: $($result.cutoff)" -ForegroundColor Cyan
    Write-Host "`n✅ Old trips have been removed from database!" -ForegroundColor Green
    
} catch {
    Write-Host "`n❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Yellow
}


















