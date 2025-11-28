# Strava Browser Login Guide

## ✅ New Feature: Browser-Based Login

The app now uses `http://localhost` as the redirect URI, which works reliably in browsers. You'll manually copy the authorization code from the browser.

## How It Works

1. Click "Connect to Strava" → Browser opens
2. Authorize on Strava
3. Browser redirects to `http://localhost/?code=YOUR_CODE`
4. Copy the code from the URL
5. Paste it in the app
6. ✅ Connected!

## Step-by-Step Instructions

### Step 1: Configure Your Strava App

Make sure your Strava app has:
- **Authorization Callback Domain**: `cyclingplus`
- **Redirect URI**: `http://localhost` (add this if not present)

### Step 2: Configure Credentials in CyclingPlus

1. Open CyclingPlus
2. Settings → Data Sources → Strava
3. Click "Configure API Credentials"
4. Enter Client ID: `178420`
5. Enter your Client Secret
6. Click "Save"

### Step 3: Connect Using Browser

**Option A: Automatic (Click Connect Button)**
1. Click "Connect to Strava"
2. Browser opens with Strava authorization page
3. Click "Authorize"
4. Browser shows: `http://localhost/?code=abc123...`
5. Copy the code (everything after `code=` and before `&` or end of URL)
6. Click "Enter Authorization Code" in the app
7. Paste the code
8. Click "Connect"
9. ✅ Done!

**Option B: Manual (Enter Code Directly)**
1. Click "Enter Authorization Code"
2. Manually open this URL in your browser:
   ```
   https://www.strava.com/oauth/authorize?client_id=178420&redirect_uri=http://localhost&response_type=code&scope=read,activity:read_all&approval_prompt=auto
   ```
3. Click "Authorize"
4. Copy the code from the redirected URL
5. Paste in the app
6. Click "Connect"
7. ✅ Done!

## Example

After authorizing, you'll see a URL like:
```
http://localhost/?state=&code=a1b2c3d4e5f6g7h8i9j0&scope=read,activity:read_all
```

Copy this part: `a1b2c3d4e5f6g7h8i9j0`

Paste it in the "Enter Authorization Code" dialog.

## Why This Method?

- ✅ **More reliable** - No custom URL scheme issues
- ✅ **Works everywhere** - Browser-based, no macOS permissions needed
- ✅ **No Strava app changes** - Just add `http://localhost` to redirect URIs
- ✅ **Simple** - Copy and paste the code

## Troubleshooting

### Browser shows "This site can't be reached"
- **This is normal!** The redirect to `localhost` will fail, but the URL contains your code
- Just copy the code from the URL bar

### Can't find the code in the URL
- Look for `code=` in the URL
- Copy everything after `code=` until the next `&` or end of URL
- Example: `http://localhost/?code=ABC123` → copy `ABC123`

### "Invalid authorization code" error
- Make sure you copied the entire code
- Don't include `code=` or `&` characters
- The code expires after a few minutes - get a new one if needed

### Still not working?
- Check that Client ID and Client Secret are correct
- Make sure you clicked "Save" after entering credentials
- Try getting a new authorization code
- Check that your Strava app has `http://localhost` in redirect URIs

## Summary

✅ **Redirect URI**: `http://localhost`  
✅ **Method**: Manual code entry  
✅ **Build**: Successful  
✅ **Ready to use**

This method is more reliable than custom URL schemes and works on all systems!
