# Strava Connection - Final Setup

## ✅ Configuration Complete

The CyclingPlus app is now configured to work with your Strava app using:
- **Redirect URI**: `cyclingplus://cyclingplus`
- **Authorization Callback Domain**: `cyclingplus`

## What Was Changed

1. **StravaAuthManager** - Redirect URI set to `cyclingplus://cyclingplus`
2. **URLSchemeHandler** - Now handles `cyclingplus://cyclingplus` callbacks
3. **Build** - ✅ Successful

## How to Connect

### Step 1: Configure Credentials
1. Open CyclingPlus
2. Go to **Settings** → **Data Sources** → **Strava**
3. Click **"Configure API Credentials"**
4. Enter your **Client ID**: `178420`
5. Enter your **Client Secret**: (from your Strava app)
6. Click **"Save"**

### Step 2: Connect
1. Click **"Connect to Strava"**
2. Browser will open with Strava authorization
3. Click **"Authorize"**
4. You'll be redirected to: `cyclingplus://cyclingplus?code=...`
5. The app should handle the callback and complete authentication

## Your Strava App Settings

Make sure your Strava app has:
- **应用程序名称**: `cyclingplus` ✅
- **授权回调域**: `cyclingplus` ✅
- **Redirect URI**: `cyclingplus://cyclingplus` (should be in the list)

## Testing the Connection

You can test manually by opening this URL in your browser:
```
https://www.strava.com/oauth/authorize?client_id=178420&redirect_uri=cyclingplus://cyclingplus&response_type=code&scope=read,activity:read_all&approval_prompt=auto
```

This should:
1. Show Strava authorization page
2. After clicking "Authorize", redirect to `cyclingplus://cyclingplus?code=...`
3. macOS should ask if you want to open CyclingPlus
4. Click "Open" and the app should complete authentication

## Troubleshooting

### If the redirect doesn't work:
1. Make sure CyclingPlus is installed and has been run at least once
2. macOS needs to register the URL scheme - try restarting the app
3. Check that your Strava app has `cyclingplus://cyclingplus` in the redirect URIs

### If authentication fails:
1. Check that Client ID and Client Secret are correct
2. Make sure you clicked "Save" after entering credentials
3. Check the app console for error messages

### If browser doesn't redirect:
1. Your Strava app might not have the redirect URI configured
2. Try adding `cyclingplus://cyclingplus` to your Strava app's redirect URIs
3. Or use `http://localhost` as redirect URI (requires code changes)

## Alternative: Use localhost

If `cyclingplus://cyclingplus` doesn't work, you can use `http://localhost` instead:
1. In your Strava app, set redirect URI to: `http://localhost`
2. I can update the code to use that instead
3. You'll need to manually copy the authorization code from the URL

Let me know if you want to try the localhost approach instead!

## Summary

✅ **App configured** to use `cyclingplus://cyclingplus`  
✅ **Build successful**  
✅ **Ready to test**  

Try connecting now and let me know if it works!
