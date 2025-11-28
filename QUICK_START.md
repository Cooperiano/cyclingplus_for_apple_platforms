# CyclingPlus - Quick Start Guide

## 🚨 First Time Setup / Database Issues

If you're experiencing database errors, run this command first:
```bash
rm -rf ~/Library/Containers/A3E2BBA8-E84E-4842-BF00-5CB00690F6E3/
```

Then rebuild and run the app.

## 🏗️ Building the App

```bash
# Clean build
xcodebuild -project cyclingplus.xcodeproj -scheme cyclingplus -destination 'platform=macOS' clean build

# Or in Xcode
# Product → Clean Build Folder (Cmd + Shift + K)
# Product → Build (Cmd + B)
# Product → Run (Cmd + R)
```

## 🔐 Setting Up Authentication

### Strava
1. Go to Settings → Data Sources → Strava
2. Click "Configure Credentials"
3. Enter your Strava API credentials
4. Click "Connect to Strava"
5. Authorize in the browser

### iGPSport
1. Go to Settings → Data Sources → iGPSport
2. Enter your iGPSport username and password
3. Click "Sign In"

## 📊 User Profile Setup

1. Go to Settings → Analysis → User Profile
2. Enter your details:
   - Name
   - Weight (kg)
   - FTP (watts)
   - Max Heart Rate (bpm)
   - Resting Heart Rate (bpm)
   - Lactate Threshold HR (bpm)
3. Click "Save Profile"
4. Power and heart rate zones will be automatically calculated

## 📁 Importing Activities

### From Files
1. Use File → Import Activity (Cmd + I)
2. Or drag and drop GPX/TCX/FIT files into the app
3. Supported formats: GPX, TCX, FIT

### From Strava/iGPSport
1. Connect your account (see Authentication above)
2. Click the sync button in the toolbar
3. Or use View → Refresh (Cmd + R)
4. Or Sync → Sync All (Cmd + Shift + S)

## 🎯 Key Features

### Activity Browser
- Search activities by name
- Filter by source (Strava, iGPSport, Files)
- Sort by date, distance, or duration
- View detailed metrics and charts

### Activity Details
- **Overview**: Key metrics and summaries
- **Charts**: Interactive power, HR, cadence, speed, elevation charts
- **Analysis**: Detailed power and heart rate analysis
- **Map**: GPS track visualization (coming soon)

### Activity Management
- Edit activity name and notes
- Export to GPX, TCX, JSON, or CSV
- Delete activities

### Power Analysis
- Normalized Power (NP)
- Intensity Factor (IF)
- Training Stress Score (TSS)
- Variability Index (VI)
- Efficiency Factor (EF)
- Estimated FTP
- Critical Power & W'
- Mean Maximal Power curves
- W' balance tracking

## ⌨️ Keyboard Shortcuts

- `Cmd + I` - Import Activity
- `Cmd + 1` - Activities View
- `Cmd + ,` - Settings
- `Cmd + R` - Refresh/Sync
- `Cmd + Shift + S` - Sync All
- `Cmd + ?` - Help

## 🐛 Troubleshooting

### Database Errors
```bash
rm -rf ~/Library/Containers/A3E2BBA8-E84E-4842-BF00-5CB00690F6E3/
```

### Build Errors
```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/cyclingplus-*

# Clean build folder in Xcode
# Product → Clean Build Folder (Cmd + Shift + K)
```

### Authentication Issues
- Make sure you have valid API credentials
- Check your internet connection
- Try logging out and back in
- Credentials are stored in macOS Keychain

### Sync Issues
- Check authentication status
- Verify internet connection
- Check sync status in the toolbar
- Try manual sync (Cmd + R)

### Using a Proxy
If you need to use a proxy to access Strava:
1. Configure your proxy in macOS System Settings → Network
2. CyclingPlus automatically uses your system proxy settings
3. Supported proxy types: HTTP, HTTPS, SOCKS5
4. See [PROXY_CONFIGURATION.md](PROXY_CONFIGURATION.md) for detailed setup instructions

## 📝 Notes

- All data is stored locally using SwiftData
- Credentials are securely stored in macOS Keychain
- Activities are cached for offline access
- Analysis is performed locally (no cloud processing)

## 🎨 UI Tips

- Use the search bar to quickly find activities
- Click on charts to inspect data points
- Drag to select time ranges in charts
- Use the stream selector to show/hide data streams
- Right-click activities for quick actions

## 🚀 Next Steps

1. Set up authentication
2. Configure user profile
3. Import or sync activities
4. Explore charts and analysis
5. Export data as needed

Enjoy analyzing your cycling data! 🚴‍♂️
