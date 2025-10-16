# Manual Cleanup Steps

Since the automated script is having permission issues, here's how to delete old trips manually:

## Option 1: Using Admin Dashboard (Easiest)

1. Open your browser
2. Go to: **http://localhost:8081/admin-dashboard.html**
3. Login with:
   - Username: `admin`
   - Password: `admin123`
4. Look for a "Maintenance" or "Cleanup" section
5. Click "Run Cleanup" or similar button

## Option 2: Using Postman/Browser Console

### Step 1: Login and Get Token
```
POST http://localhost:8081/api/auth/signin
Content-Type: application/json

{
  "usernameOrEmail": "admin",
  "password": "admin123"
}
```

Copy the `token` from the response.

### Step 2: Run Cleanup
```
POST http://localhost:8081/api/admin/maintenance/cleanup?dryRun=false
Authorization: Bearer YOUR_TOKEN_HERE
```

## Option 3: Direct Database Cleanup

Run this SQL in your MySQL database:

```sql
-- See what would be deleted
SELECT * FROM voyages WHERE departure_time < DATE_SUB(NOW(), INTERVAL 1 DAY);

-- Delete old trips (this will cascade to reservations, payments, etc.)
DELETE FROM voyages WHERE departure_time < DATE_SUB(NOW(), INTERVAL 1 DAY);
```

## Option 4: Wait for Scheduled Cleanup

The cleanup service runs automatically at **2:15 AM** every day.
It will delete trips older than 1 day.

Just wait until tomorrow morning and the old trips will be gone automatically!

## Current Status

- **Old trips to delete**: 8 trips
- **Old reservations to delete**: 7 reservations
- **Cutoff date**: October 9, 2025 00:00

## Why the Script Fails

The automated script is getting a 403 Forbidden error, likely due to:
1. Spring Security role configuration mismatch
2. Token timing issues
3. Double @PreAuthorize annotations causing conflicts

**Recommendation**: Use Option 1 (Admin Dashboard) or Option 4 (wait for scheduled cleanup)


















