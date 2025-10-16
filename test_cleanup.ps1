# Test and Run Cleanup Service
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Cleanup Service Tester" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Login as admin
Write-Host "Logging in as admin..." -ForegroundColor Yellow
$loginData = '{"usernameOrEmail":"admin","password":"admin123"}'
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8081/api/auth/signin" `
        -Method Post -Body $loginData -ContentType "application/json"
    $token = $response.token
    Write-Host "✅ Login successful!" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "❌ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$headers = @{ Authorization = "Bearer $token" }

# Step 1: Check cleanup stats
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Current Cleanup Stats" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
try {
    $stats = Invoke-RestMethod -Uri "http://localhost:8081/api/admin/maintenance/cleanup/stats" -Headers $headers
    Write-Host "Last Run Time: $($stats.lastRunTime)" -ForegroundColor Yellow
    Write-Host "Retention Days: $($stats.retentionDays) days" -ForegroundColor Yellow
    Write-Host "Next Scheduled Run: $($stats.nextScheduledRun)" -ForegroundColor Yellow
    if ($stats.lastRunStats -and $stats.lastRunStats.Count -gt 0) {
        Write-Host "Last Run Deleted:" -ForegroundColor Yellow
        Write-Host "  - Voyages: $($stats.lastRunStats.deletedVoyages)" -ForegroundColor White
        Write-Host "  - Reservations: $($stats.lastRunStats.deletedReservations)" -ForegroundColor White
    }
    Write-Host ""
} catch {
    Write-Host "⚠️  Could not get cleanup stats" -ForegroundColor Yellow
    Write-Host ""
}

# Step 2: Dry run to see what would be deleted
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Dry Run (Preview)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
try {
    $dryRun = Invoke-RestMethod -Uri "http://localhost:8081/api/admin/maintenance/cleanup?dryRun=true" `
        -Method Post -Headers $headers
    
    Write-Host "Cutoff Date: $($dryRun.cutoff)" -ForegroundColor Yellow
    Write-Host "Would Delete:" -ForegroundColor Yellow
    Write-Host "  - Trips: $($dryRun.voyages)" -ForegroundColor White
    Write-Host "  - Reservations: $($dryRun.reservations)" -ForegroundColor White
    Write-Host ""
    
    if ($dryRun.voyages -eq 0) {
        Write-Host "✅ No old trips to delete!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 0
    }
    
} catch {
    Write-Host "❌ Dry run failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}

# Step 3: Ask user if they want to proceed
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Confirm Deletion" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  This will permanently delete:" -ForegroundColor Yellow
Write-Host "   - $($dryRun.voyages) old trips" -ForegroundColor White
Write-Host "   - $($dryRun.reservations) associated reservations" -ForegroundColor White
Write-Host "   - All related payments and GPS points" -ForegroundColor White
Write-Host ""

$confirmation = Read-Host "Do you want to proceed? (yes/no)"

if ($confirmation -ne "yes") {
    Write-Host ""
    Write-Host "❌ Cleanup canceled by user" -ForegroundColor Yellow
    exit 0
}

# Step 4: Actually run cleanup
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Running Cleanup..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
try {
    $result = Invoke-RestMethod -Uri "http://localhost:8081/api/admin/maintenance/cleanup?dryRun=false" `
        -Method Post -Headers $headers
    
    Write-Host ""
    Write-Host "✅ Cleanup completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Results:" -ForegroundColor Yellow
    Write-Host "  - Deleted Trips: $($result.deletedVoyages)" -ForegroundColor White
    Write-Host "  - Deleted Reservations: $($result.deletedReservations)" -ForegroundColor White
    Write-Host "  - Run Time: $($result.runTime)" -ForegroundColor White
    Write-Host ""
    
    # Step 5: Verify in admin dashboard
    Write-Host "✅ Old trips have been removed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Verify in admin dashboard:" -ForegroundColor Cyan
    Write-Host "http://localhost:8081/admin-dashboard.html" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "❌ Cleanup failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


















