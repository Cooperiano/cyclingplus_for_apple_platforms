# Connection Troubleshooting Guide

This guide helps you troubleshoot connection issues with Strava and iGPSport.

## Strava Connection Issues

### Problem: "Strava client credentials not configured"

**Solution:**
1. Go to Settings → Data Sources → Strava
2. Click "Configure API Credentials"
3. Follow these steps to get your credentials:
   - Visit [Strava API Settings](https://www.strava.com/settings/api)
   - If you don't have an app, click "Create an App"
   - Fill in the application details:
     - **Application Name**: CyclingPlus (or your preferred name)
     - **Category**: Data Importer
     - **Club**: Leave blank
     - **Website**: http://localhost (or your website)
     - **Authorization Callback Domain**: `cyclingplus`
     - **Redirect URI**: `cyclingplus://auth`
   - Click "Create"
   - Copy your **Client ID** and **Client Secret**
4. Paste them into the CyclingPlus configuration dialog
5. Click "Save"
6. Click "Connect to Strava"

### Problem: "Authorization failed" or redirect doesn't work

**Possible causes:**
- Incorrect redirect URI in Strava app settings
- Browser blocking the custom URL scheme

**Solution:**
1. Verify your Strava app settings:
   - Authorization Callback Domain must be: `cyclingplus`
   - Redirect URI must include: `cyclingplus://auth`
2. Try the connection again
3. If the browser asks for permission to open CyclingPlus, click "Allow"

### Problem: "Invalid or expired token"

**Solution:**
1. Go to Settings → Data Sources → Strava
2. Click "Disconnect"
3. Click "Connect to Strava" again to re-authenticate

## iGPSport Connection Issues

### Problem: "Login failed" or "Invalid credentials"

**Possible causes:**
- Incorrect username or password
- Account locked due to too many failed attempts
- Network connectivity issues
- Using wrong iGPSport region (this app connects to China region)

**Solution:**
1. Verify your credentials:
   - Make sure you're using your iGPSport China account credentials
   - The app connects to `prod.zh.igpsport.com` (China region)
   - If you have an international account, you may need to create a China account
2. Check your network:
   - Ensure you have internet connectivity
   - Try accessing https://prod.zh.igpsport.com in your browser
3. Reset your password if needed:
   - Visit the iGPSport website to reset your password
   - Wait a few minutes before trying again

### Problem: "Session expired"

**Solution:**
1. Go to Settings → Data Sources → iGPSport
2. Click "Disconnect"
3. Enter your credentials again and click "Login to iGPSport"

### Problem: "Rate limit exceeded"

**Solution:**
- Wait 15-30 minutes before trying again
- The API has rate limits to prevent abuse
- Avoid making too many sync requests in a short time

## General Connection Tips

### Check Connection Status
- Look for the colored dots in Settings:
  - 🟠 Orange = Strava connected
  - 🔵 Blue = iGPSport connected
  - ⚪ Gray = No connections

### Test Your Connection
1. After connecting, go to the main activity list
2. Click the sync button (↻) in the toolbar
3. Check for any error messages
4. Look at the sync status in Settings → Account Management

### Network Issues
If you're having persistent connection issues:
1. Check your firewall settings
2. Ensure CyclingPlus has network access permissions
3. Try disabling VPN if you're using one
4. Check if your network blocks custom URL schemes (for Strava)

## Proxy-Related Issues

### Problem: "Operation not permitted" or connection fails with proxy

**Possible causes:**
- System proxy is configured but app cannot access network
- Proxy server is not reachable
- Proxy authentication required but not configured

**Solution:**
1. Verify your system proxy settings:
   - Open System Settings → Network
   - Select your active network connection
   - Click "Details..." → "Proxies"
   - Ensure proxy settings are correct
2. Test proxy connectivity:
   - Try accessing https://www.strava.com in Safari
   - If Safari works but CyclingPlus doesn't, the proxy may be blocking the app
3. Check proxy server status:
   - Ensure the proxy server is running and accessible
   - Verify the proxy address and port are correct
4. For authenticated proxies:
   - Configure proxy authentication in System Settings
   - macOS will prompt for credentials when needed

### Problem: Connection timeout with proxy

**Possible causes:**
- Proxy server is slow or overloaded
- Network latency is high
- Proxy is blocking Strava API requests

**Solution:**
1. Check proxy server performance:
   - Test with other applications
   - Contact your network administrator if using corporate proxy
2. Try without proxy temporarily:
   - Disable proxy in System Settings → Network
   - Test if connection works
   - Re-enable proxy if needed
3. Increase timeout tolerance:
   - Wait longer for initial connection
   - Proxy connections may take 10-30 seconds longer

### Problem: OAuth redirect fails with proxy

**Possible causes:**
- Proxy is interfering with custom URL scheme
- Browser cannot communicate with app through proxy

**Solution:**
1. Ensure proxy allows local connections:
   - Add `localhost` and `127.0.0.1` to proxy bypass list
   - Add `cyclingplus://` to allowed URL schemes
2. Configure proxy bypass in System Settings:
   - System Settings → Network → Details → Proxies
   - Add to "Bypass proxy settings for these Hosts & Domains":
     - `localhost`
     - `127.0.0.1`
     - `*.local`
3. Try the browser-based OAuth flow:
   - The redirect should work even with proxy
   - Allow the browser to open CyclingPlus when prompted

### Proxy Configuration Guide

For detailed proxy setup instructions, see [PROXY_CONFIGURATION.md](PROXY_CONFIGURATION.md)

Supported proxy types:
- HTTP proxy
- HTTPS proxy  
- SOCKS5 proxy
- Authenticated proxies (with username/password)

### Testing Proxy Connection

To verify your proxy is working with CyclingPlus:
1. Configure proxy in System Settings
2. Open CyclingPlus
3. Go to Settings → Network Diagnostics (if available)
4. Or try connecting to Strava
5. Check Console.app for network logs if issues persist

### Still Having Issues?

If you've tried all the above and still can't connect:
1. Check the app logs for detailed error messages
2. Try restarting the application
3. Check if there are any system updates available
4. Report the issue with:
   - The exact error message
   - Steps you took before the error
   - Your macOS version
   - Whether you're using a VPN or proxy

## Security Notes

- Your credentials are stored securely in macOS Keychain
- Strava uses OAuth 2.0 (your password is never stored)
- iGPSport credentials are encrypted in Keychain
- You can disconnect at any time to revoke access
