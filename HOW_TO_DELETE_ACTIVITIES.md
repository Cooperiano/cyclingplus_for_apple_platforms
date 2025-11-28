# How to Delete Activities - Quick Guide

## Step-by-Step Instructions

### 1. Open the Activity
- Go to the **Activities** list (main view)
- Click on the activity you want to delete
- The activity detail view will open on the right

### 2. Open the Actions Menu
- Look for the **menu button** (•••) in the top-right corner of the detail view
- It's in the toolbar area, next to the activity title
- Click the menu button

### 3. Select Delete
- A menu will appear with these options:
  - ✏️ Edit Activity
  - 📤 Export (with submenu for formats)
  - 🗑️ **Delete Activity** (in red)
- Click **"Delete Activity"**

### 4. Confirm Deletion
- An alert dialog will appear asking for confirmation
- The message will say: "Are you sure you want to delete '[Activity Name]'? This action cannot be undone."
- Click **"Delete"** to confirm (or "Cancel" to abort)

### 5. Activity Deleted
- The activity is immediately removed from the database
- You'll be returned to the activity list
- The deleted activity will no longer appear

## Visual Guide

```
┌─────────────────────────────────────────────────────────────┐
│ Activities                                    [Search Bar]   │
├─────────────────────┬───────────────────────────────────────┤
│                     │  Morning Ride              [•••] ← Click here!
│ Activity List       │  ┌─────────────────────────────────┐  │
│                     │  │ Edit Activity                   │  │
│ • Morning Ride      │  │ ─────────────────────────────── │  │
│ • Evening Ride      │  │ Export ▶                        │  │
│ • Weekend Long      │  │ ─────────────────────────────── │  │
│ • Recovery Ride     │  │ Delete Activity (red)    ← Select this!
│                     │  └─────────────────────────────────┘  │
│                     │                                        │
│                     │  [Activity Details]                    │
│                     │  Distance: 45.2 km                     │
│                     │  Duration: 1h 30m                      │
│                     │  ...                                   │
└─────────────────────┴───────────────────────────────────────┘
```

## Important Reminders

⚠️ **Deletion is Permanent**
- Once deleted, the activity cannot be recovered from CyclingPlus
- All analysis data (power, heart rate, AI insights) is also deleted
- The original activity on Strava/iGPSport is NOT affected

✅ **To Restore a Deleted Activity**
- Go to Settings → Account Management
- Click "Full Sync All"
- The activity will be re-downloaded from the source
- All analysis will be recalculated

## Alternative: Export Before Deleting

If you want to keep a backup:
1. Click the menu button (•••)
2. Select **Export** → Choose format (GPX recommended)
3. Save the file to your computer
4. Then delete the activity
5. You can re-import the file later if needed

## Quick Tips

- **Review before deleting**: Make sure you're deleting the right activity
- **Check for duplicates**: If you have the same activity from multiple sources, delete the duplicate
- **Export important rides**: Before deleting significant activities, export them for your records
- **Bulk operations coming**: Future updates will support deleting multiple activities at once

## Current Limitations

- Can only delete one activity at a time
- Must open detail view to access delete option
- No undo/trash bin (deletion is immediate)
- No swipe-to-delete in list view

These limitations will be addressed in future updates!
