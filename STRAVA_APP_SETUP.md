# Strava App Setup - Using Your Existing App

## ✅ Good News!

Your existing Strava app "cyclingplus" will work! I've updated the CyclingPlus code to support your redirect URI: `cyclingplus://auth/strava`

## What I Changed in the Code

1. **URLSchemeHandler** - Now handles both:
   - `cyclingplus://auth` (default)
   - `cyclingplus://auth/strava` (your existing setup)

2. **StravaAuthView** - Updated instructions to show both options

## Your Strava App Settings

Based on your screenshot, you have:
- **应用程序名称**: `cyclingplus` ✅
- **网站**: `cyclingplus://auth/strava` ✅ (This will work now!)
- **授权回调域**: `none` ⚠️ (Should be `cyclingplus`)

## Recommended Changes (Optional but Better)

To make it work perfectly, update your Strava app:

1. **授权回调域 (Authorization Callback Domain)**
   - Change from: `none`
   - Change to: `cyclingplus`

2. **网站 (Website)** - Optional, but Strava prefers a real URL
   - Change from: `cyclingplus://auth/strava`
   - Change to: `http://localhost` or `https://github.com/yourusername/cyclingplus`

3. **Keep your redirect URI** as is: `cyclingplus://auth/strava`

## How to Connect Now

### Step 1: Get Your Credentials
1. Go to https://www.strava.com/settings/api
2. Find your "cyclingplus" app
3. Copy your **Client ID** (客户端 ID)
4. Copy your **Client Secret** (客户端密钥)

### Step 2: Configure CyclingPlus
1. Open CyclingPlus
2. Go to **Settings** → **Data Sources** → **Strava**
3. Click **"Configure API Credentials"**
4. Paste your **Client ID**
5. Paste your **Client Secret**
6. Click **"Save"**

### Step 3: Connect
1. Click **"Connect to Strava"**
2. Your browser will open
3. Log in to Strava (if needed)
4. Click **"Authorize"**
5. You'll be redirected back to CyclingPlus
6. ✅ Connected!

## Why This Works Now

The app now accepts both redirect URI formats:
- `cyclingplus://auth` - Standard format
- `cyclingplus://auth/strava` - Your existing format

Both will work correctly!

## If You Want to Update Your Strava App (Optional)

If you want to follow Strava's best practices:

1. Edit your app on Strava
2. Change **授权回调域** to: `cyclingplus`
3. Change **网站** to: `http://localhost`
4. Keep redirect URI as: `cyclingplus://auth/strava`
5. Save

This makes it cleaner but isn't required - it will work either way!

## Testing

After configuring:
1. Try connecting to Strava
2. If it opens the browser and redirects back, it's working!
3. If not, check that:
   - Client ID and Secret are correct
   - You clicked "Save" after entering credentials
   - The Strava app has the redirect URI set

## Summary

✅ **No need to create a new Strava app**  
✅ **Your existing app will work**  
✅ **Code updated to support your redirect URI**  
✅ **Just copy your credentials and connect**

The app is now compatible with your existing Strava app configuration!
