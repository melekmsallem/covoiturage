# Admin Dashboard Testing Script
# This script demonstrates how to test the admin dashboard endpoints

Write-Host "=== Admin Dashboard Testing Script ===" -ForegroundColor Green
Write-Host ""

# Base URL
$baseUrl = "http://localhost:8080/api"

# Test endpoints (no authentication required)
$testEndpoints = @(
    "/test/sprint4",
    "/test/sprint4/features", 
    "/test/sprint4/dashboard-test",
    "/test/sprint4/system-health",
    "/test/sprint4/popular-routes",
    "/test/sprint4/top-drivers",
    "/test/sprint4/user-stats",
    "/test/sprint4/trip-stats",
    "/test/sprint4/payment-stats",
    "/test/sprint4/rating-stats",
    "/test/sprint4/notification-stats",
    "/test/sprint4/system-metrics"
)

Write-Host "Testing Sprint 4 Admin Dashboard Endpoints..." -ForegroundColor Yellow
Write-Host ""

foreach ($endpoint in $testEndpoints) {
    $url = $baseUrl + $endpoint
    Write-Host "Testing: $url" -ForegroundColor Cyan
    
    try {
        $response = Invoke-WebRequest -Uri $url -Method GET -TimeoutSec 10
        Write-Host "✅ SUCCESS: Status $($response.StatusCode)" -ForegroundColor Green
        
        # Try to parse JSON response
        try {
            $jsonResponse = $response.Content | ConvertFrom-Json
            Write-Host "   Response: $($jsonResponse | ConvertTo-Json -Compress)" -ForegroundColor Gray
        } catch {
            Write-Host "   Response: $($response.Content.Substring(0, [Math]::Min(100, $response.Content.Length)))..." -ForegroundColor Gray
        }
    } catch {
        Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}

Write-Host "=== Admin Endpoints (Require Authentication) ===" -ForegroundColor Yellow
Write-Host ""

# Admin endpoints (require authentication)
$adminEndpoints = @(
    "/admin/dashboard/stats",
    "/admin/users",
    "/admin/users/statistics", 
    "/admin/trips/statistics",
    "/admin/payments/statistics",
    "/admin/ratings/statistics",
    "/admin/notifications/statistics",
    "/admin/system/health",
    "/admin/system/metrics"
)

Write-Host "Note: Admin endpoints require ADMIN role authentication" -ForegroundColor Yellow
Write-Host "To test admin endpoints, you need to:" -ForegroundColor Yellow
Write-Host "1. Login as an admin user" -ForegroundColor White
Write-Host "2. Get JWT token" -ForegroundColor White  
Write-Host "3. Include token in Authorization header: 'Bearer <token>'" -ForegroundColor White
Write-Host ""

foreach ($endpoint in $adminEndpoints) {
    $url = $baseUrl + $endpoint
    Write-Host "Admin Endpoint: $url" -ForegroundColor Magenta
}

Write-Host ""
Write-Host "=== Testing Instructions ===" -ForegroundColor Green
Write-Host ""
Write-Host "1. Start the application: ./gradlew bootRun" -ForegroundColor White
Write-Host "2. Run this script: .\test_admin_dashboard.ps1" -ForegroundColor White
Write-Host "3. For admin endpoints, use Postman or curl with JWT token" -ForegroundColor White
Write-Host ""
Write-Host "Example curl command for admin endpoint:" -ForegroundColor Yellow
Write-Host 'curl -H "Authorization: Bearer YOUR_JWT_TOKEN" http://localhost:8080/api/admin/dashboard/stats' -ForegroundColor Gray
Write-Host ""
Write-Host "=== Postman Collection ===" -ForegroundColor Green
Write-Host "Import this JSON into Postman for easy testing:" -ForegroundColor White

# Generate Postman collection JSON
$postmanCollection = @{
    info = @{
        name = "Covoiturage Admin Dashboard API"
        description = "Admin dashboard endpoints for carpooling application"
        schema = "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
    }
    item = @()
}

# Add test endpoints
foreach ($endpoint in $testEndpoints) {
    $postmanCollection.item += @{
        name = "Test $endpoint"
        request = @{
            method = "GET"
            header = @()
            url = @{
                raw = "{{baseUrl}}$endpoint"
                host = @("{{baseUrl}}")
                path = $endpoint.Split('/')
            }
        }
    }
}

# Add admin endpoints
foreach ($endpoint in $adminEndpoints) {
    $postmanCollection.item += @{
        name = "Admin $endpoint"
        request = @{
            method = "GET"
            header = @(
                @{
                    key = "Authorization"
                    value = "Bearer {{adminToken}}"
                    type = "text"
                }
            )
            url = @{
                raw = "{{baseUrl}}$endpoint"
                host = @("{{baseUrl}}")
                path = $endpoint.Split('/')
            }
        }
    }
}

$postmanJson = $postmanCollection | ConvertTo-Json -Depth 10
Write-Host $postmanJson -ForegroundColor Gray





































