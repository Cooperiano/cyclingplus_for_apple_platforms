# Activity Management Guide

## Overview

CyclingPlus provides comprehensive activity management features including viewing, editing, exporting, and deleting activities.

## Viewing Activities

### Activity List
- All activities are displayed in the main activity list
- Activities are sorted by date (newest first) by default
- Each activity shows:
  - Activity name
  - Date
  - Distance, duration, elevation gain
  - Average power (if available)
  - Source icon (Strava, iGPSport, or imported file)

### Filtering Activities
1. Click the **filter button** (three horizontal lines) in the toolbar
2. Select a source:
   - All Sources
   - Strava
   - iGPSport
   - GPX/TCX/FIT (imported files)

### Sorting Activities
1. Click the **sort button** (up/down arrows) in the toolbar
2. Choose sort order:
   - Date (Newest First) - default
   - Date (Oldest First)
   - Distance (Longest)
   - Duration (Longest)

### Searching Activities
- Use the search bar at the top
- Search by activity name
- Results update as you type

## Viewing Activity Details

1. Click on any activity in the list
2. The detail view shows:
   - **Overview**: Key metrics, weather, equipment
   - **Charts**: Power, heart rate, speed, elevation graphs
   - **Analysis**: Power zones, training metrics, AI insights
   - **Map**: Route visualization (if GPS data available)

## Editing Activities

### Edit Activity Information
1. Open an activity detail view
2. Click the **menu button** (•••) in the top-right toolbar
3. Select **"Edit Activity"**
4. Modify:
   - Activity name
   - Activity type
   - Description
   - Equipment used
5. Click **"Save"** to apply changes

## Exporting Activities

### Export Single Activity
1. Open an activity detail view
2. Click the **menu button** (•••) in the top-right toolbar
3. Select **"Export"**
4. Choose format:
   - **GPX** - GPS Exchange Format (compatible with most apps)
   - **TCX** - Training Center XML (Garmin format)
   - **FIT** - Flexible and Interoperable Data Transfer (Garmin/Wahoo)
   - **JSON** - Raw data export
5. Choose save location
6. Click **"Save"**

### Export Multiple Activities
(Feature coming soon - bulk export)

## Deleting Activities

### Delete Single Activity

**Method 1: From Detail View**
1. Open an activity detail view
2. Click the **menu button** (•••) in the top-right toolbar
3. Select **"Delete Activity"** (red text)
4. Confirm deletion in the alert dialog
5. Click **"Delete"** to permanently remove the activity

**Method 2: From List View**
(Currently requires opening detail view first)

### Important Notes About Deletion

⚠️ **Deletion is Permanent**
- Deleted activities cannot be recovered
- All associated data is removed:
  - Activity streams (power, heart rate, GPS data)
  - Power analysis
  - Heart rate analysis
  - AI analysis
- The activity is only deleted from CyclingPlus
- Original data on Strava/iGPSport is NOT affected

### What Gets Deleted
When you delete an activity, the following data is removed:
- ✅ Activity metadata (name, date, distance, etc.)
- ✅ Activity streams (all sensor data)
- ✅ Power analysis (FTP, TSS, power zones, etc.)
- ✅ Heart rate analysis (HR zones, TRIMP, etc.)
- ✅ AI analysis and insights
- ✅ GPS route data

### What Doesn't Get Deleted
- ❌ Original activity on Strava (remains unchanged)
- ❌ Original activity on iGPSport (remains unchanged)
- ❌ Exported files you've saved
- ❌ User profile settings
- ❌ Other activities

## Bulk Operations

### Delete Multiple Activities
(Feature coming soon)

### Re-sync Deleted Activities
If you accidentally delete an activity:
1. Go to **Settings** → **Account Management**
2. Click **"Full Sync All"**
3. The activity will be re-downloaded from Strava/iGPSport
4. All analysis will be recalculated

## Activity Management Tips

### Keep Your Data Organized
- Use descriptive activity names
- Add notes/descriptions for important rides
- Tag equipment used for maintenance tracking

### Regular Backups
- Export important activities periodically
- Store exports in a safe location
- Consider exporting before major app updates

### Clean Up Duplicates
- If you sync from multiple sources, you may get duplicates
- Review and delete duplicate activities
- Keep the version with the most complete data

### Performance Considerations
- Large numbers of activities (1000+) may slow down the app
- Consider archiving old activities by exporting and deleting
- Keep recent activities (last 1-2 years) for best performance

## Keyboard Shortcuts

(Coming soon)
- ⌘+Delete - Delete selected activity
- ⌘+E - Edit selected activity
- ⌘+S - Export selected activity

## Troubleshooting

### Can't Delete Activity
- Make sure you have the activity selected
- Check if the app has write permissions
- Try restarting the app

### Deleted Activity Still Appears
- The app may need to refresh
- Try closing and reopening the activity list
- If it persists, restart the app

### Want to Restore Deleted Activity
- Use "Full Sync All" to re-download from source
- If it was an imported file, re-import the file
- If you exported it, re-import the exported file

## Future Features

Coming soon:
- Bulk delete operations
- Activity archiving
- Trash/recycle bin with undo
- Keyboard shortcuts
- Context menu in list view
- Swipe to delete
- Activity merging
- Duplicate detection
