# Database Reset Instructions

## Problem
The app is experiencing CoreData/SwiftData schema migration errors due to model changes. Common errors include:
- `table ZACTIVITY has no column named Z12ACTIVITIES`
- `no such column: t0.Z9POWERZONES`
- `no such column: t0.Z9MEANMAXIMALPOWER`

These indicate a schema mismatch between the code and the existing database.

## Solution
Delete the existing database to allow SwiftData to create a fresh schema.

## Steps to Reset Database

### Option 1: Delete from Terminal (Recommended)
```bash
# Delete the app's container data
rm -rf ~/Library/Containers/A3E2BBA8-E84E-4842-BF00-5CB00690F6E3/

# Or just delete the database file
rm ~/Library/Containers/A3E2BBA8-E84E-4842-BF00-5CB00690F6E3/Data/Library/Application\ Support/default.store*
```

### Option 2: Delete from Finder
1. Open Finder
2. Press `Cmd + Shift + G` to open "Go to Folder"
3. Paste: `~/Library/Containers/`
4. Find folder starting with `A3E2BBA8-E84E-4842-BF00-5CB00690F6E3`
5. Delete the entire folder
6. Empty Trash

### Option 3: Clean Build (Alternative)
1. In Xcode: Product → Clean Build Folder (Cmd + Shift + K)
2. Delete Derived Data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/cyclingplus-*
   ```
3. Rebuild the app

## After Reset
1. Restart the app
2. The database will be recreated with the correct schema
3. You'll need to:
   - Re-authenticate with Strava
   - Re-authenticate with iGPSport
   - Re-import any local files
   - Reconfigure user profile settings

## Prevention
This issue occurred because the UserProfile model has a relationship to Activity that wasn't properly migrated. In production, you would use SwiftData migration policies to handle schema changes gracefully.

## Quick Reset Command
Run this single command to reset everything:
```bash
rm -rf ~/Library/Containers/A3E2BBA8-E84E-4842-BF00-5CB00690F6E3/ && echo "Database reset complete. Restart the app."
```

## What Was Fixed
The issue was caused by a `var activities: [Activity]` relationship in the UserProfile model that wasn't properly configured. This has been removed in the latest code, so after resetting the database, the app should work correctly.

## Note
After running the reset command and restarting the app:
- The database will be recreated with the correct schema
- All authentication and data will need to be set up again
- This is a one-time fix - future updates will handle migrations properly
