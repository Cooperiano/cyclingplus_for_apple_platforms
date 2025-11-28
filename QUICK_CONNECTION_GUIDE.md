# Quick Connection Guide

## Connect to Strava (5 minutes)

### Step 1: Get Strava API Credentials
1. Visit https://www.strava.com/settings/api
2. Click "Create an App" (if you don't have one)
3. Fill in:
   - **Application Name**: CyclingPlus
   - **Authorization Callback Domain**: `cyclingplus`
   - **Redirect URI**: `cyclingplus://auth`
4. Copy your **Client ID** and **Client Secret**

### Step 2: Configure CyclingPlus
1. Open CyclingPlus
2. Go to **Settings** → **Data Sources** → **Strava**
3. Click **"Configure API Credentials"**
4. Paste your Client ID and Client Secret
5. Click **"Save"**

### Step 3: Connect
1. Click **"Connect to Strava"**
2. Your browser will open - log in to Strava
3. Click **"Authorize"** to grant access
4. You'll be redirected back to CyclingPlus
5. ✅ You're connected!

## Connect to iGPSport (2 minutes)

### Step 1: Prepare Your Credentials
- You need your iGPSport China account credentials
- This app connects to `prod.zh.igpsport.com`
- If you don't have a China account, you may need to create one

### Step 2: Connect
1. Open CyclingPlus
2. Go to **Settings** → **Data Sources** → **iGPSport**
3. Enter your **username** and **password**
4. Click **"Login to iGPSport"**
5. ✅ You're connected!

## Verify Your Connections

1. Go to **Settings** → **Account Management**
2. You should see:
   - 🟠 Strava: Connected (with your name)
   - 🔵 iGPSport: Connected (with your username)
3. Click **"Sync All Services"** to test

## First Sync

After connecting, your first sync will:
- Download your recent activities (last 30 days by default)
- Import activity details and streams (power, heart rate, etc.)
- Calculate power metrics (FTP, TSS, etc.)
- This may take a few minutes depending on how many activities you have

## Need Help?

See [CONNECTION_TROUBLESHOOTING.md](CONNECTION_TROUBLESHOOTING.md) for detailed troubleshooting steps.
