# 🧹 Cleanup Service Guide - Automatic Trip Deletion

**Issue**: Old trips in the past are not being deleted automatically  
**Solution**: Configure and test the cleanup service

---

## 📋 Current Configuration

### Cleanup Service Status
- ✅ **Enabled**: Yes (`@EnableScheduling` is active)
- ✅ **Location**: `CleanupService.java`
- ⏰ **Schedule**: Runs daily at **02:15 AM**
- 📅 **Retention**: **1 day** (trips older than 1 day are deleted)

### Why Old Trips Still Exist
1. **Scheduled time hasn't occurred yet** (runs at 2:15 AM)
2. **Service only deletes trips older than retention period** (1 day)
3. **Need to trigger manually or wait for scheduled run**

---

## 🔍 How the Cleanup Works

### Automatic Schedule
```java
@Scheduled(cron = "0 15 2 * * *")  // Runs at 02:15 AM every day
public void cleanupExpiredTrips() {
    runCleanup(false);
}
```

### What Gets Deleted
1. **Trips** older than retention period (1 day by default)
2. **Reservations** associated with those trips
3. **Payments** associated with those reservations
4. **GPS Points** associated with those trips

### Retention Period
Configured in `application.properties`:
```properties
cleanup.retention.days=1
```

**Current setting**: Trips older than **1 day** will be deleted

---

## 🧪 Test the Cleanup Service

### Option 1: Dry Run (See What Would Be Deleted)

**Using Browser or Postman**:
```
POST http://localhost:8081/api/admin/maintenance/cleanup?dryRun=true
Authorization: Bearer YOUR_ADMIN_TOKEN
```

**Using curl** (PowerShell):
```powershell
# First, get your admin token (if not already logged in)
$loginData = '{"usernameOrEmail":"admin","password":"admin123"}'
$response = Invoke-RestMethod -Uri "http://localhost:8081/api/auth/signin" `
  -Method Post -Body $loginData -ContentType "application/json"
$token = $response.token

# Test cleanup (dry run - won't delete anything)
$headers = @{ Authorization = "Bearer $token" }
Invoke-RestMethod -Uri "http://localhost:8081/api/admin/maintenance/cleanup?dryRun=true" `
  -Method Post -Headers $headers | ConvertTo-Json
```

**Expected Response**:
```json
{
  "cutoff": "2025-10-09T00:00:00",
  "voyages": 5,
  "reservations": 3
}
```

This shows:
- `cutoff`: Date before which trips will be deleted
- `voyages`: Number of trips that would be deleted
- `reservations`: Number of reservations that would be deleted

---

### Option 2: Actually Delete Old Trips

**⚠️ WARNING**: This will permanently delete data!

**Using Browser or Postman**:
```
POST http://localhost:8081/api/admin/maintenance/cleanup?dryRun=false
Authorization: Bearer YOUR_ADMIN_TOKEN
```

**Using curl** (PowerShell):
```powershell
# Use the same $headers from above
Invoke-RestMethod -Uri "http://localhost:8081/api/admin/maintenance/cleanup?dryRun=false" `
  -Method Post -Headers $headers | ConvertTo-Json
```

**Expected Response**:
```json
{
  "cutoff": "2025-10-09T00:00:00",
  "deletedVoyages": 5,
  "deletedReservations": 3,
  "runTime": "2025-10-10T12:30:00"
}
```

---

### Option 3: Check Cleanup Statistics

See when cleanup last ran and what it deleted:

```
GET http://localhost:8081/api/admin/maintenance/cleanup/stats
```

**Using curl**:
```powershell
Invoke-RestMethod -Uri "http://localhost:8081/api/admin/maintenance/cleanup/stats" | ConvertTo-Json
```

**Response**:
```json
{
  "lastRunTime": "2025-10-10T02:15:00",
  "lastRunStats": {
    "deletedVoyages": 3,
    "deletedReservations": 2,
    "runTime": "2025-10-10T02:15:00"
  },
  "retentionDays": 1,
  "nextScheduledRun": "Daily at 02:15"
}
```

---

## ⚙️ Configuration Options

### 1. Change Retention Period

**File**: `src/main/resources/application.properties`

```properties
# Delete trips older than X days
cleanup.retention.days=1

# Options:
# 0 = delete all past trips immediately
# 1 = delete trips older than 1 day (default)
# 7 = delete trips older than 1 week
# 30 = delete trips older than 1 month
```

**After changing**: Restart Spring Boot application

---

### 2. Change Schedule Time

**File**: `src/main/java/esprit/pfe/covoiturage_final/services/CleanupService.java`

**Current**:
```java
@Scheduled(cron = "0 15 2 * * *")  // 02:15 AM daily
```

**Options**:
```java
// Every hour
@Scheduled(cron = "0 0 * * * *")

// Every 30 minutes
@Scheduled(cron = "0 */30 * * * *")

// Every day at midnight
@Scheduled(cron = "0 0 0 * * *")

// Every day at 3 AM
@Scheduled(cron = "0 0 3 * * *")

// Every Sunday at 2 AM
@Scheduled(cron = "0 0 2 * * SUN")
```

**Cron Format**: `second minute hour day month weekday`

**After changing**: Recompile and restart application

---

## 🚀 Quick Solutions

### Solution 1: Trigger Cleanup Manually (Now)

Run this command to delete old trips immediately:

```powershell
# Login as admin
$loginData = '{"usernameOrEmail":"admin","password":"admin123"}'
$response = Invoke-RestMethod -Uri "http://localhost:8081/api/auth/signin" -Method Post -Body $loginData -ContentType "application/json"
$token = $response.token
$headers = @{ Authorization = "Bearer $token" }

# Run cleanup
$result = Invoke-RestMethod -Uri "http://localhost:8081/api/admin/maintenance/cleanup?dryRun=false" -Method Post -Headers $headers
$result | ConvertTo-Json

Write-Host "✅ Cleanup complete!" -ForegroundColor Green
Write-Host "Deleted $($result.deletedVoyages) trips" -ForegroundColor Yellow
Write-Host "Deleted $($result.deletedReservations) reservations" -ForegroundColor Yellow
```

---

### Solution 2: Run Cleanup More Frequently

**Change retention to 0 days (delete all past trips)**:

Edit `application.properties`:
```properties
cleanup.retention.days=0
```

Restart app, then trips older than today will be deleted at 2:15 AM.

---

### Solution 3: Change Schedule to Run Hourly

Edit `CleanupService.java` line 49:
```java
// OLD:
@Scheduled(cron = "0 15 2 * * *")

// NEW (run every hour):
@Scheduled(cron = "0 0 * * * *")
```

Rebuild and restart application.

---

## 📊 Verify Cleanup Worked

### 1. Check via Admin Dashboard
```
http://localhost:8081/admin-dashboard.html
```
- Login as admin
- Check "Total Trips" count
- Should decrease after cleanup

### 2. Check via API
```powershell
# Get all trips
Invoke-RestMethod -Uri "http://localhost:8081/api/admin/trips" -Headers $headers

# Count should be reduced
```

### 3. Check Database Directly
```sql
SELECT COUNT(*) FROM voyages WHERE departure_time < NOW();
```

Should return 0 or very few if cleanup worked.

---

## 🐛 Troubleshooting

### Issue 1: Cleanup Not Running
**Check**:
- Is `@EnableScheduling` present in `CovoiturageFinalApplication.java`? ✅ Yes
- Is the application running? Check logs
- Wait until 2:15 AM for scheduled run

**Solution**: Trigger manually via API

### Issue 2: Nothing Gets Deleted
**Possible Causes**:
- Retention period too high (all trips are within retention)
- No trips in database older than retention period
- Database constraints preventing deletion

**Solution**:
- Set `cleanup.retention.days=0` to delete all past trips
- Run dry run to see what would be deleted
- Check logs for errors

### Issue 3: "Authorization Failed"
**Cause**: Not logged in as admin

**Solution**:
- Login as admin first
- Get JWT token
- Include in Authorization header

---

## 📝 Recommended Settings

### For Development
```properties
# Delete trips older than 0 days (all past trips)
cleanup.retention.days=0
```

```java
// Run every hour
@Scheduled(cron = "0 0 * * * *")
```

### For Production
```properties
# Keep trips for 7 days for record-keeping
cleanup.retention.days=7
```

```java
// Run daily at 2 AM
@Scheduled(cron = "0 0 2 * * *")
```

---

## 🔒 Security Note

Only **ADMIN** users can trigger cleanup manually via:
- `POST /api/admin/maintenance/cleanup`

The scheduled automatic cleanup runs regardless of user permissions.

---

## 🎯 Summary

### Current Status
- ✅ Cleanup service is **enabled** and **configured**
- ⏰ Runs automatically at **2:15 AM daily**
- 📅 Deletes trips older than **1 day**
- 🔐 Admin can trigger **manually** anytime

### To Delete Old Trips Now
1. Login as admin
2. Call: `POST /api/admin/maintenance/cleanup?dryRun=false`
3. Verify in admin dashboard

### To Change Settings
1. Edit `application.properties` for retention days
2. Edit `CleanupService.java` for schedule time
3. Restart application

---

## ✅ Quick Test Commands

### Test 1: See What Would Be Deleted (Safe)
```powershell
# In browser/Postman:
POST http://localhost:8081/api/admin/maintenance/cleanup?dryRun=true
Headers: Authorization: Bearer YOUR_TOKEN
```

### Test 2: Actually Delete Old Trips
```powershell
# In browser/Postman:
POST http://localhost:8081/api/admin/maintenance/cleanup?dryRun=false
Headers: Authorization: Bearer YOUR_TOKEN
```

### Test 3: Check Cleanup Stats
```powershell
# In browser/Postman:
GET http://localhost:8081/api/admin/maintenance/cleanup/stats
```

---

**Next Steps**: 
1. Test the cleanup with dry run
2. If results look good, run actual cleanup
3. Adjust retention period if needed
4. Consider changing schedule if you want more frequent cleanup

**The cleanup service is working, it just needs to be triggered or wait for the scheduled time!** ✅


















