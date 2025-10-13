# PowerShell script to execute the database cleanup
# Make sure MySQL is running and accessible

Write-Host "🧹 Starting database cleanup and recreation..." -ForegroundColor Yellow

# Check if MySQL is accessible
try {
    $mysqlTest = Get-Command mysql -ErrorAction Stop
    Write-Host "✅ MySQL CLI found at: $($mysqlTest.Source)" -ForegroundColor Green
} catch {
    Write-Host "❌ MySQL CLI not found. Please install MySQL or use phpMyAdmin to execute the SQL script manually." -ForegroundColor Red
    Write-Host "📄 SQL script location: cleanup_and_recreate.sql" -ForegroundColor Yellow
    exit 1
}

# Execute the SQL script
Write-Host "🔄 Executing cleanup script..." -ForegroundColor Yellow
try {
    mysql -u root -p covoiturage_db < cleanup_and_recreate.sql
    Write-Host "✅ Database cleanup completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "❌ Error executing SQL script: $_" -ForegroundColor Red
    Write-Host "📄 Please execute cleanup_and_recreate.sql manually in phpMyAdmin" -ForegroundColor Yellow
}

Write-Host "🎯 Next steps:" -ForegroundColor Cyan
Write-Host "1. Restart the Spring Boot application" -ForegroundColor White
Write-Host "2. Check the dashboard at http://localhost:8081/admin-dashboard.html" -ForegroundColor White
Write-Host "3. Verify that trips show correct city names" -ForegroundColor White





