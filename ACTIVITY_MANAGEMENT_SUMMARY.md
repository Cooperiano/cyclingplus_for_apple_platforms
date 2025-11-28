# Activity Management - Feature Summary

## ✅ Currently Available Features

### Viewing Activities
- ✅ List view with all activities
- ✅ Detailed view for each activity
- ✅ Search by activity name
- ✅ Filter by source (Strava, iGPSport, imported files)
- ✅ Sort by date, distance, or duration
- ✅ Activity count display

### Managing Individual Activities
- ✅ **Edit activity** (name, type, description, equipment)
- ✅ **Export activity** (GPX, TCX, FIT, JSON formats)
- ✅ **Delete activity** (with confirmation dialog)

### Activity Details
- ✅ Overview tab (metrics, weather, equipment)
- ✅ Charts tab (power, heart rate, speed, elevation)
- ✅ Analysis tab (power zones, training metrics, AI insights)
- ✅ Map tab (route visualization)

## How to Delete Activities

### Quick Steps:
1. Click on an activity in the list
2. Click the menu button (•••) in the top-right
3. Select "Delete Activity"
4. Confirm deletion

### What Happens:
- Activity is permanently removed from CyclingPlus
- All associated data is deleted (streams, analysis, etc.)
- Original activity on Strava/iGPSport remains unchanged
- No undo available (deletion is immediate)

### To Restore:
- Use "Full Sync All" to re-download from source
- Or re-import the file if it was imported

## Implementation Details

### Files Involved:
- `ActivityActionsView.swift` - Provides the delete action menu
- `ActivityDetailView.swift` - Shows the actions menu in toolbar
- `DataRepository.swift` - Handles database deletion
- `ActivityListView.swift` - Displays activities and handles selection

### Delete Flow:
1. User clicks menu → Delete Activity
2. Confirmation alert appears
3. User confirms deletion
4. `deleteActivity()` method is called
5. Activity is removed from SwiftData model context
6. Changes are saved to database
7. UI automatically updates (activity disappears from list)

## Safety Features

### Confirmation Dialog
- Prevents accidental deletion
- Shows activity name in confirmation message
- Requires explicit "Delete" button click
- Provides "Cancel" option

### Data Integrity
- Deletion is transactional (all or nothing)
- Related data (streams, analysis) is automatically deleted via SwiftData relationships
- Database consistency is maintained

## Future Enhancements

### Planned Features:
- 🔜 Bulk delete (select multiple activities)
- 🔜 Swipe to delete in list view
- 🔜 Context menu in list view
- 🔜 Trash/recycle bin with undo
- 🔜 Keyboard shortcuts (⌘+Delete)
- 🔜 Activity archiving
- 🔜 Duplicate detection and merging

### Under Consideration:
- Activity tagging/categorization
- Custom activity filters
- Activity notes/comments
- Activity sharing
- Activity comparison

## Technical Notes

### SwiftData Integration
- Activities use `@Model` macro for persistence
- Deletion uses `modelContext.delete()`
- Relationships are automatically handled
- Changes are saved with `modelContext.save()`

### Error Handling
- Delete failures are caught and logged
- UI shows error alerts if deletion fails
- Database rollback on error

### Performance
- Deletion is immediate (no background processing)
- UI updates automatically via SwiftData observation
- No manual refresh needed

## Documentation

For more details, see:
- `ACTIVITY_MANAGEMENT_GUIDE.md` - Comprehensive guide
- `HOW_TO_DELETE_ACTIVITIES.md` - Quick visual guide
- `CONNECTION_TROUBLESHOOTING.md` - Connection issues
- `QUICK_CONNECTION_GUIDE.md` - Setup instructions
