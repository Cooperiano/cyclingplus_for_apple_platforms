# CyclingPlus macOS Rebuild Instructions

## Current Situation
The previous build was targeting iOS/iPadOS and running on Mac through compatibility mode. We need to create a proper macOS-native application.

## Steps to Rebuild for macOS

### Option 1: Create New Xcode Project (Recommended)
1. Open Xcode
2. File → New → Project
3. Select **macOS** → **App**
4. Project Name: **CyclingPlus**
5. Interface: **SwiftUI**
6. Language: **Swift**
7. Storage: **SwiftData**
8. Check: **Create Git repository** (optional)
9. Save in the current directory

### Option 2: Modify Existing Project
If you want to keep the existing project:
1. Open `cyclingplus.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select the **cyclingplus** target
4. Go to **General** tab
5. Under **Supported Destinations**:
   - Add **macOS** (check the box)
   - Set minimum macOS version to 14.0 or later
   - Optionally remove iOS/iPadOS if you only want macOS
6. Clean build folder (Product → Clean Build Folder)
7. Build for macOS

## Files to Copy from cyclingplus_old

All the code we wrote is ready to use. You need to copy these folders/files:

### Models (cyclingplus_old/cyclingplus/Models/)
- Activity.swift
- ActivityStreams.swift
- PowerAnalysis.swift
- HeartRateAnalysis.swift
- AIAnalysis.swift
- UserProfile.swift
- StravaModels.swift
- IGPSportModels.swift
- CyclingPlusError.swift

### Services (cyclingplus_old/cyclingplus/Services/)
- DataRepository.swift
- StravaAuthManager.swift
- StravaAPIService.swift
- StravaSyncService.swift
- IGPSportAuthManager.swift
- IGPSportAPIService.swift
- IGPSportSyncService.swift
- SyncCoordinator.swift
- URLSchemeHandler.swift
- FileParsingService.swift
- SampleDataService.swift

### Views (cyclingplus_old/cyclingplus/Views/)
- ContentView.swift
- StravaAuthView.swift
- IGPSportAuthView.swift
- SettingsView.swift
- AccountManagementView.swift
- ConnectionStatusWidget.swift
- SyncMenuButton.swift
- FileImportView.swift

### Main App File
- cyclingplusApp.swift (or CyclingPlusApp.swift)

### Specs (for reference)
- .kiro/specs/strava-data-migration/

## URL Scheme Configuration

Add to Info.plist or in Xcode under Info tab:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.cyclingplus.oauth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>cyclingplus</string>
        </array>
    </dict>
</array>
```

Or in Xcode:
1. Select target → Info tab
2. Add URL Types
3. Identifier: `com.cyclingplus.oauth`
4. URL Schemes: `cyclingplus`

## What's Already Implemented

✅ **Complete Features:**
1. SwiftData models for all cycling data
2. Strava OAuth authentication
3. iGPSport authentication
4. Data synchronization services
5. Background sync with configurable intervals
6. File import UI (GPX/TCX/FIT)
7. Account management UI
8. Connection status widgets

🚧 **To Be Implemented:**
- Power analysis algorithms
- Heart rate analysis
- Data visualizations (charts)
- AI integration
- Full file parsing (GPX/TCX/FIT)

## Quick Start After Rebuild

1. Build and run the app
2. Go to Settings → Account Management
3. Connect to Strava or iGPSport
4. Use the sync button to fetch activities
5. Import local files via the + menu

## Notes

- All code is macOS-compatible (uses NSWorkspace instead of UIApplication)
- SwiftUI works identically on macOS
- Keychain storage works the same
- File system access is the same
- The only difference is the project configuration

## If You Need Help

The complete working code is in `cyclingplus_old/cyclingplus/`. Just copy it to the new macOS project and it should work immediately after fixing any import issues.