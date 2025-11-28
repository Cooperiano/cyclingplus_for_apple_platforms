# Proxy Functionality Testing Guide

This guide provides comprehensive instructions for testing proxy support in CyclingPlus.

## Overview

CyclingPlus now supports system-level proxy configurations including:
- HTTP proxies
- HTTPS proxies  
- SOCKS5 proxies
- Authenticated proxies

## Prerequisites

- macOS system with network access
- Proxy server for testing (optional - see recommendations below)
- CyclingPlus app with network entitlements configured

## Recommended Proxy Tools

### Charles Proxy
- **Website**: https://www.charlesproxy.com
- **Type**: HTTP/HTTPS proxy with SSL proxying
- **Default Port**: 8888
- **Best For**: Debugging HTTP/HTTPS traffic

### Proxyman
- **Website**: https://proxyman.io
- **Type**: Native macOS HTTP/HTTPS proxy
- **Default Port**: 9090
- **Best For**: macOS-native proxy debugging

### SSH SOCKS Proxy
- **Command**: `ssh -D 1080 -N user@server`
- **Type**: SOCKS5 proxy
- **Best For**: Testing SOCKS5 support

## Test Scenarios

### 1. HTTP Proxy Testing

#### Setup
1. Open **System Settings** → **Network**
2. Select your active network connection
3. Click **Details...**
4. Go to **Proxies** tab
5. Check **Web Proxy (HTTP)**
6. Enter proxy details:
   - **Web Proxy Server**: `127.0.0.1` (or your proxy server)
   - **Port**: `8888` (or your proxy port)
7. Click **OK**

#### Test Steps
1. Launch CyclingPlus
2. Check Console.app for network permission logs
3. Navigate to Settings → Network Diagnostics
4. Click "Test Connection"
5. Verify connection succeeds

#### Expected Results
- ✅ Connection test passes
- ✅ No "Operation not permitted" errors
- ✅ Proxy logs show app traffic
- ✅ Network status shows "Available"

#### Verification
```bash
# Check proxy logs (Charles Proxy example)
# Look for requests to www.strava.com in Charles
```

---

### 2. HTTPS Proxy Testing

#### Setup
1. Open **System Settings** → **Network** → **Proxies**
2. Check **Secure Web Proxy (HTTPS)**
3. Enter proxy details:
   - **Secure Web Proxy Server**: `127.0.0.1`
   - **Port**: `8888`
4. If using Charles/Proxyman, install SSL certificate:
   - Charles: **Help** → **SSL Proxying** → **Install Charles Root Certificate**
   - Proxyman: **Certificate** → **Install Certificate on this Mac**
5. Click **OK**

#### Test Steps
1. Launch CyclingPlus
2. Click "Connect Strava"
3. Complete OAuth flow in browser
4. Verify callback is received
5. Check that token exchange succeeds

#### Expected Results
- ✅ Browser opens for OAuth
- ✅ OAuth callback is received
- ✅ Token exchange completes
- ✅ Athlete profile loads
- ✅ HTTPS requests visible in proxy logs

#### Verification
```bash
# Check app logs
log stream --predicate 'subsystem == "com.cyclingplus"' --level debug

# Look for:
# - "Network connectivity verified"
# - "OAuth token exchange successful"
```

---

### 3. SOCKS5 Proxy Testing

#### Setup (Using SSH)
1. Create SOCKS5 proxy via SSH:
   ```bash
   ssh -D 1080 -N user@your-server.com
   ```
2. Open **System Settings** → **Network** → **Proxies**
3. Check **SOCKS Proxy**
4. Enter proxy details:
   - **SOCKS Proxy Server**: `127.0.0.1`
   - **Port**: `1080`
5. Click **OK**

#### Test Steps
1. Launch CyclingPlus
2. Test all network operations:
   - Connection test
   - Strava authentication
   - Activity sync
   - Activity detail loading
3. Monitor SSH connection for traffic

#### Expected Results
- ✅ All network operations succeed
- ✅ Traffic goes through SOCKS proxy
- ✅ No connection errors

---

### 4. OAuth Authentication Flow Testing

#### Setup
Configure any proxy type (HTTP, HTTPS, or SOCKS5)

#### Test Steps
1. Launch CyclingPlus
2. Go to Settings
3. Click "Connect Strava"
4. Browser opens to Strava authorization page
5. Log in to Strava (if needed)
6. Click "Authorize"
7. Browser redirects to `cyclingplus://auth/strava?code=...`
8. App receives callback
9. Token exchange occurs
10. Athlete profile loads

#### Expected Results
- ✅ Browser opens successfully
- ✅ Authorization page loads
- ✅ Callback is received by app
- ✅ Token exchange succeeds through proxy
- ✅ Athlete profile displays
- ✅ "Connected to Strava" status shows

#### Verification
Check proxy logs for these requests:
1. `GET https://www.strava.com/oauth/authorize`
2. `POST https://www.strava.com/oauth/token`
3. `GET https://www.strava.com/api/v3/athlete`

---

### 5. Error Scenario Testing

#### Test 5.1: Invalid Proxy Address

**Setup**:
- Configure proxy with invalid address: `127.0.0.1:9999`

**Expected Results**:
- ❌ Connection fails
- ✅ Error message: "Cannot connect to host"
- ✅ Suggestion to check proxy settings
- ✅ No "Operation not permitted" error

#### Test 5.2: Proxy Timeout

**Setup**:
- Configure proxy that doesn't respond
- Set short timeout (10 seconds)

**Expected Results**:
- ❌ Connection times out
- ✅ Error message: "Connection timeout"
- ✅ Suggestion to check proxy server

#### Test 5.3: Proxy Authentication Required

**Setup**:
- Configure proxy requiring authentication
- Don't provide credentials in System Settings

**Expected Results**:
- ❌ Connection fails with 407 Proxy Authentication Required
- ✅ Clear error message about authentication

**Note**: macOS System Settings should prompt for proxy credentials automatically.

#### Test 5.4: Proxy Blocks Strava

**Setup**:
- Configure proxy with Strava blocked

**Expected Results**:
- ❌ Connection fails
- ✅ Error message indicates connection issue
- ✅ No app crash

---

### 6. No Proxy Testing (Regression)

#### Setup
1. Open **System Settings** → **Network** → **Proxies**
2. Uncheck all proxy options
3. Click **OK**

#### Test Steps
1. Launch CyclingPlus
2. Test all features:
   - Connection test
   - Strava authentication
   - Activity sync
   - Activity list
   - Activity details
   - File import
3. Verify everything works normally

#### Expected Results
- ✅ All features work without proxy
- ✅ Direct connection to Strava
- ✅ No proxy-related errors
- ✅ Normal performance

---

## Automated Tests

Run the automated test suite:

```bash
# Run all tests
xcodebuild test -scheme cyclingplus -destination 'platform=macOS'

# Run only proxy tests
xcodebuild test -scheme cyclingplus -destination 'platform=macOS' -only-testing:cyclingplusTests/ProxyFunctionalityTests
```

### Test Coverage

The automated tests verify:
- ✅ Network entitlements are present
- ✅ Basic network connectivity
- ✅ URLSession configuration
- ✅ System proxy detection
- ✅ OAuth URL generation
- ✅ OAuth callback parsing
- ✅ Error detection and handling
- ✅ Strava API connectivity
- ✅ Concurrent requests
- ✅ No-proxy functionality

---

## Verification Checklist

Use this checklist to verify all proxy functionality:

### Network Permissions
- [ ] Network client entitlement present in app
- [ ] No "Operation not permitted" errors
- [ ] Network permission service reports "Available"

### HTTP Proxy
- [ ] Connection test succeeds
- [ ] Strava API requests work
- [ ] Proxy logs show app traffic

### HTTPS Proxy
- [ ] OAuth flow completes
- [ ] Token exchange succeeds
- [ ] SSL/TLS works correctly
- [ ] Proxy logs show HTTPS traffic

### SOCKS5 Proxy
- [ ] All network operations work
- [ ] Traffic goes through SOCKS proxy

### OAuth Flow
- [ ] Browser opens for authorization
- [ ] Callback is received
- [ ] Token exchange succeeds
- [ ] Athlete profile loads

### Error Handling
- [ ] Invalid proxy shows clear error
- [ ] Timeout shows clear error
- [ ] Auth failure shows clear error
- [ ] No app crashes on errors

### Regression
- [ ] Works without proxy
- [ ] All features functional
- [ ] Normal performance

---

## Troubleshooting

### Issue: "Operation not permitted" error

**Cause**: Missing network client entitlement

**Solution**:
1. Check `cyclingplus.entitlements` file exists
2. Verify it contains `com.apple.security.network.client`
3. Check Xcode project settings include entitlements
4. Clean build folder and rebuild

### Issue: Proxy not being used

**Cause**: URLSession configuration overriding system proxy

**Solution**:
1. Verify using `URLSession.shared` or `URLSessionConfiguration.default`
2. Check `connectionProxyDictionary` is nil
3. Don't manually configure proxy in code

### Issue: SSL/TLS errors with HTTPS proxy

**Cause**: Proxy SSL certificate not trusted

**Solution**:
1. Install proxy's root certificate
2. Trust certificate in Keychain Access
3. Restart app

### Issue: Timeout with proxy

**Cause**: Proxy server not responding

**Solution**:
1. Verify proxy server is running
2. Check proxy address and port
3. Test proxy with curl:
   ```bash
   curl -x http://127.0.0.1:8888 https://www.strava.com
   ```

---

## Logging and Debugging

### View App Logs

```bash
# Stream all app logs
log stream --predicate 'subsystem == "com.cyclingplus"' --level debug

# Filter network-related logs
log stream --predicate 'subsystem == "com.cyclingplus" AND category == "NetworkPermission"'
```

### Check Network Requests

```bash
# Monitor network activity (requires sudo)
sudo nettop -p cyclingplus

# Check proxy configuration
scutil --proxy
```

### Verify Entitlements

```bash
# Check app entitlements
codesign -d --entitlements - /path/to/cyclingplus.app

# Should show:
# <key>com.apple.security.network.client</key>
# <true/>
```

---

## Test Results Template

Use this template to document test results:

```
## Proxy Testing Results

**Date**: YYYY-MM-DD
**Tester**: [Name]
**App Version**: [Version]
**macOS Version**: [Version]

### HTTP Proxy
- Proxy Tool: [Charles/Proxyman/Other]
- Proxy Address: [Address:Port]
- Result: [✅ Pass / ❌ Fail]
- Notes: [Any observations]

### HTTPS Proxy
- Proxy Tool: [Charles/Proxyman/Other]
- Proxy Address: [Address:Port]
- SSL Certificate: [Installed / Not Installed]
- Result: [✅ Pass / ❌ Fail]
- Notes: [Any observations]

### SOCKS5 Proxy
- Proxy Tool: [SSH/Other]
- Proxy Address: [Address:Port]
- Result: [✅ Pass / ❌ Fail]
- Notes: [Any observations]

### OAuth Flow
- Proxy Type: [HTTP/HTTPS/SOCKS5]
- Browser Opens: [✅ Yes / ❌ No]
- Callback Received: [✅ Yes / ❌ No]
- Token Exchange: [✅ Success / ❌ Fail]
- Result: [✅ Pass / ❌ Fail]

### Error Scenarios
- Invalid Proxy: [✅ Pass / ❌ Fail]
- Timeout: [✅ Pass / ❌ Fail]
- Auth Required: [✅ Pass / ❌ Fail]

### Regression (No Proxy)
- All Features: [✅ Pass / ❌ Fail]
- Performance: [Normal / Degraded]

### Issues Found
[List any issues discovered]

### Overall Result
[✅ All Tests Pass / ⚠️ Some Issues / ❌ Major Issues]
```

---

## Additional Resources

- [Apple Network Extension Documentation](https://developer.apple.com/documentation/networkextension)
- [URLSession Proxy Configuration](https://developer.apple.com/documentation/foundation/urlsessionconfiguration)
- [App Sandbox Entitlements](https://developer.apple.com/documentation/bundleresources/entitlements)
- [Charles Proxy Documentation](https://www.charlesproxy.com/documentation/)
- [Proxyman Documentation](https://docs.proxyman.io/)

---

## Support

If you encounter issues during testing:

1. Check Console.app for detailed error logs
2. Verify entitlements configuration
3. Test with different proxy tools
4. Review the troubleshooting section
5. Check system proxy settings in Terminal:
   ```bash
   scutil --proxy
   ```

For questions or issues, refer to:
- `PROXY_CONFIGURATION.md` - Proxy setup guide
- `CONNECTION_TROUBLESHOOTING.md` - Connection issues
- `QUICK_START.md` - General setup
