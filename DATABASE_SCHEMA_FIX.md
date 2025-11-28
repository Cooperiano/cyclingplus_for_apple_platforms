# Database Schema Fix - Quick Guide

## The Error You're Seeing

```
no such column: t0.Z9POWERZONES
no such column: t0.Z9MEANMAXIMALPOWER
```

## What This Means

The database was created before we added the power zone distribution and MMP (Mean Maximal Power) features. The database schema needs to be updated.

## Quick Fix (30 seconds)

### Step 1: Close the App
Make sure CyclingPlus is completely closed.

### Step 2: Run This Command

Open Terminal and paste this command:

```bash
rm -rf ~/Library/Containers/A3E2BBA8-E84E-4842-BF00-5CB00690F6E3/ && echo "✅ Database reset complete!"
```

Press Enter.

### Step 3: Restart the App

Launch CyclingPlus again. The database will be recreated with the correct schema.

## What You'll Need to Do After Reset

Since the database is reset, you'll need to:

1. **Re-connect to Strava** (if you were using it)
   - Go to Settings → Data Sources → Strava
   - Configure API credentials
   - Connect again

2. **Re-connect to iGPSport** (if you were using it)
   - Go to Settings → Data Sources → iGPSport
   - Enter username and password
   - Login again

3. **Re-sync your activities**
   - Go to Settings → Account Management
   - Click "Full Sync All"
   - Your activities will be downloaded again

4. **Re-import any local files** (if you had imported GPX/TCX/FIT files)
   - Go to File → Import Activity
   - Import your files again

## Why This Happened

We added new features to the power analysis:
- Power zone distribution analysis
- Mean Maximal Power (MMP) curves
- W' balance tracking

These features require new database columns. SwiftData doesn't automatically migrate the schema in development mode, so we need to reset the database.

## Will This Happen Again?

No! Once the database is reset with the new schema, it will work correctly. Future updates will handle migrations more gracefully.

## Alternative: Keep Your Data

If you have important data you don't want to lose, you can:

1. **Export all activities first**
   - Open each activity
   - Click the menu (•••)
   - Export as FIT or GPX
   - Save to a folder

2. **Reset the database** (command above)

3. **Re-import the exported files**
   - File → Import Activity
   - Select all your exported files

This preserves your activity data through the reset.

## Detailed Instructions

For more detailed reset instructions, see [RESET_DATABASE.md](RESET_DATABASE.md)

## What's New After Reset

Once you reset and re-sync, you'll have access to:
- ✅ Power zone distribution (time in each zone)
- ✅ Mean Maximal Power curves
- ✅ W' balance tracking
- ✅ FIT file import with full data
- ✅ Improved power analysis

## Still Having Issues?

If the error persists after reset:

1. Make sure the app is completely closed
2. Run the reset command again
3. Check that the folder was actually deleted:
   ```bash
   ls ~/Library/Containers/ | grep A3E2BBA8
   ```
   (Should return nothing)
4. Restart your Mac (if needed)
5. Launch the app again

## Summary

**Problem:** Database schema mismatch  
**Solution:** Reset database (one command)  
**Time:** 30 seconds  
**Data loss:** Yes, but can be re-synced  
**Frequency:** One-time fix
