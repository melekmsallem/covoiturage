# PowerShell script to populate the database
Write-Host "🚀 Populating database with correct data..." -ForegroundColor Yellow

# Check if MySQL is accessible
try {
    $mysqlTest = Get-Command mysql -ErrorAction Stop
    Write-Host "✅ MySQL CLI found at: $($mysqlTest.Source)" -ForegroundColor Green
} catch {
    Write-Host "❌ MySQL CLI not found. Please use phpMyAdmin or another MySQL client to execute the SQL script manually." -ForegroundColor Red
    Write-Host "📄 SQL script location: populate_database.sql" -ForegroundColor Yellow
    Write-Host "🔧 You can also use the Spring Boot application to create trips through the web interface." -ForegroundColor Cyan
    exit 1
}

# Execute the SQL script
Write-Host "🔄 Executing populate script..." -ForegroundColor Yellow
try {
    mysql -u root -p covoiturage_db < populate_database.sql
    Write-Host "✅ Database populated successfully!" -ForegroundColor Green
    Write-Host "🎉 You can now access your dashboard at: http://localhost:8081/admin-dashboard.html" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Error executing SQL script: $_" -ForegroundColor Red
    Write-Host "📄 Please execute the SQL script manually using phpMyAdmin or another MySQL client." -ForegroundColor Yellow
}





