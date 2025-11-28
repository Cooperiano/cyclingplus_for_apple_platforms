# Proxy Configuration Guide for CyclingPlus

This guide explains how to configure CyclingPlus to work with network proxies on macOS.

## Overview

CyclingPlus automatically uses your macOS system proxy settings. You don't need to configure anything within the app itself - just set up your proxy in System Settings and the app will use it automatically.

**Supported Proxy Types:**
- HTTP proxy
- HTTPS proxy (secure)
- SOCKS5 proxy
- Authenticated proxies (username/password)

## Why Use a Proxy?

You might need a proxy if:
- Your organization requires all internet traffic to go through a corporate proxy
- You're in a region where direct access to Strava is restricted
- You want to route traffic through a specific network path
- Your network administrator requires proxy usage for security

## Configuring System Proxy on macOS

### Step 1: Open Network Settings

1. Click the Apple menu () → **System Settings**
2. Click **Network** in the sidebar
3. Select your active network connection (Wi-Fi or Ethernet)
4. Click **Details...** button

### Step 2: Configure Proxy Settings

1. Click the **Proxies** tab
2. Check the box for the proxy type you want to use:
   - **Web Proxy (HTTP)** - for HTTP traffic
   - **Secure Web Proxy (HTTPS)** - for HTTPS traffic (recommended)
   - **SOCKS Proxy** - for SOCKS5 proxy
3. Enter your proxy server details:
   - **Proxy Server**: Enter the proxy server address (e.g., `proxy.company.com` or `192.168.1.100`)
   - **Port**: Enter the proxy port (e.g., `8080`, `3128`, `1080`)
4. If your proxy requires authentication:
   - Check **Proxy server requires password**
   - Enter your **Username**
   - Enter your **Password**
5. Click **OK** to save

### Step 3: Configure Proxy Bypass (Important!)

To ensure local connections and OAuth redirects work properly:

1. In the Proxies tab, scroll down to **Bypass proxy settings for these Hosts & Domains**
2. Add the following entries (one per line):
   ```
   localhost
   127.0.0.1
   *.local
   169.254/16
   ```
3. Click **OK** to save

### Step 4: Test Your Configuration

1. Open Safari and try accessing https://www.strava.com
2. If Safari can access Strava, your proxy is configured correctly
3. Launch CyclingPlus and try connecting to Strava

## Common Proxy Configurations

### Corporate HTTP Proxy

```
Proxy Type: Web Proxy (HTTP) + Secure Web Proxy (HTTPS)
Server: proxy.company.com
Port: 8080
Authentication: Yes (if required)
Bypass: localhost, 127.0.0.1, *.local
```

### SOCKS5 Proxy

```
Proxy Type: SOCKS Proxy
Server: socks.example.com
Port: 1080
Authentication: Optional
Bypass: localhost, 127.0.0.1, *.local
```

### Local Proxy (e.g., Charles, Fiddler)

```
Proxy Type: Web Proxy (HTTP) + Secure Web Proxy (HTTPS)
Server: 127.0.0.1 or localhost
Port: 8888 (Charles) or 8888 (Fiddler)
Authentication: No
Bypass: (leave empty or add specific domains)
```

## Troubleshooting Proxy Issues

### Issue: "Operation not permitted" Error

**Symptoms:**
- Connection fails immediately
- Error message mentions "NSPOSIXErrorDomain Code=1"

**Cause:**
- Network permissions issue (should be resolved in latest version)

**Solution:**
1. Ensure you're using the latest version of CyclingPlus
2. Check that the app has network access permissions
3. Try restarting the app
4. If issue persists, try disabling and re-enabling the proxy

### Issue: Connection Timeout

**Symptoms:**
- Connection hangs for a long time
- Eventually times out with no response

**Cause:**
- Proxy server is not reachable
- Proxy server is slow or overloaded
- Firewall blocking connection to proxy

**Solution:**
1. Verify proxy server address and port are correct
2. Test proxy with Safari or curl:
   ```bash
   curl -x http://proxy.example.com:8080 https://www.strava.com
   ```
3. Check if proxy server is running and accessible
4. Contact your network administrator if using corporate proxy
5. Try a different proxy server if available

### Issue: Authentication Fails

**Symptoms:**
- Prompted for proxy credentials repeatedly
- "407 Proxy Authentication Required" error

**Cause:**
- Incorrect proxy username or password
- Proxy credentials expired
- Proxy authentication method not supported

**Solution:**
1. Verify your proxy username and password
2. Re-enter credentials in System Settings → Network → Proxies
3. Check with your network administrator for correct credentials
4. Some proxy authentication methods (NTLM, Kerberos) may require additional configuration

### Issue: OAuth Redirect Fails

**Symptoms:**
- Browser opens for Strava authorization
- After authorizing, nothing happens
- App doesn't receive the authorization

**Cause:**
- Proxy is blocking the custom URL scheme redirect
- Proxy bypass not configured for localhost

**Solution:**
1. Add `localhost` and `127.0.0.1` to proxy bypass list
2. Ensure the proxy allows custom URL schemes
3. Try the authorization flow again
4. If still failing, temporarily disable proxy, authorize, then re-enable

### Issue: Slow Performance

**Symptoms:**
- Connections work but are very slow
- Sync takes much longer than expected

**Cause:**
- Proxy server is slow or overloaded
- High network latency through proxy
- Proxy is in a distant geographic location

**Solution:**
1. This is expected behavior with proxies - they add latency
2. Be patient during sync operations
3. Consider syncing during off-peak hours
4. Use a faster or closer proxy server if available
5. For large syncs, let the app run in the background

### Issue: SSL/TLS Certificate Errors

**Symptoms:**
- "Certificate invalid" or "SSL error" messages
- HTTPS connections fail

**Cause:**
- Proxy is performing SSL inspection
- Proxy certificate not trusted by macOS

**Cause:**
1. Install your organization's proxy SSL certificate:
   - Get the certificate from your IT department
   - Double-click to install in Keychain Access
   - Set to "Always Trust"
2. Or disable SSL inspection if possible
3. Contact your network administrator for assistance

## Testing Your Proxy Setup

### Test 1: Basic Connectivity

```bash
# Test HTTP connection through proxy
curl -x http://proxy.example.com:8080 http://www.strava.com

# Test HTTPS connection through proxy
curl -x http://proxy.example.com:8080 https://www.strava.com

# Test with authentication
curl -x http://username:password@proxy.example.com:8080 https://www.strava.com
```

### Test 2: Strava API Access

```bash
# Test Strava API endpoint
curl -x http://proxy.example.com:8080 https://www.strava.com/api/v3/athlete
```

### Test 3: CyclingPlus Connection

1. Open CyclingPlus
2. Go to Settings → Data Sources → Strava
3. Click "Connect to Strava"
4. Complete the OAuth flow
5. Check for any error messages

### Test 4: Check System Logs

If you're experiencing issues, check the system logs:

```bash
# Open Console app
open -a Console

# Filter for CyclingPlus
# Search for: process:cyclingplus

# Look for network-related errors
```

## Advanced Configuration

### Using PAC (Proxy Auto-Config) Files

If your organization uses PAC files:

1. System Settings → Network → Details → Proxies
2. Check **Auto Proxy Discovery** or **Automatic Proxy Configuration**
3. Enter the PAC file URL if required
4. CyclingPlus will automatically use the PAC configuration

### Using Multiple Proxies

If you need different proxies for different protocols:

1. Configure each proxy type separately:
   - Web Proxy (HTTP) → one proxy
   - Secure Web Proxy (HTTPS) → another proxy
   - SOCKS Proxy → yet another proxy
2. CyclingPlus will use the appropriate proxy for each connection type

### Proxy Environment Variables

CyclingPlus respects system proxy settings, but if you need to override:

```bash
# Set proxy environment variables (for testing)
export http_proxy=http://proxy.example.com:8080
export https_proxy=http://proxy.example.com:8080
export no_proxy=localhost,127.0.0.1

# Launch CyclingPlus from terminal
open -a CyclingPlus
```

## Security Considerations

### Proxy Credentials

- Proxy credentials are stored in macOS Keychain
- They are encrypted and protected by your system password
- CyclingPlus never sees or stores proxy credentials directly
- macOS handles all proxy authentication automatically

### HTTPS and Encryption

- All Strava API requests use HTTPS (encrypted)
- Proxy cannot see the content of HTTPS requests (unless doing SSL inspection)
- Your Strava credentials and data remain secure
- OAuth tokens are transmitted securely

### Corporate Proxies

If using a corporate proxy:
- Your organization may log all proxy traffic
- SSL inspection may allow viewing of HTTPS content
- Follow your organization's acceptable use policies
- Contact IT if you have security concerns

## Disabling Proxy

If you need to temporarily disable the proxy:

### Option 1: System-Wide Disable

1. System Settings → Network → Details → Proxies
2. Uncheck all proxy types
3. Click OK
4. Restart CyclingPlus

### Option 2: Add to Bypass List

1. System Settings → Network → Details → Proxies
2. Add `*.strava.com` to bypass list
3. This allows direct connection to Strava while keeping proxy for other traffic

## Getting Help

If you're still experiencing proxy issues:

1. **Check the logs:**
   - Open Console.app
   - Filter for "cyclingplus"
   - Look for network errors

2. **Gather information:**
   - Proxy type (HTTP/HTTPS/SOCKS5)
   - Proxy server address and port
   - Whether authentication is required
   - Exact error message
   - macOS version

3. **Try without proxy:**
   - Temporarily disable proxy
   - Test if app works without proxy
   - This helps isolate the issue

4. **Contact support:**
   - Provide the information gathered above
   - Include any error messages
   - Describe your network setup

## Summary

- CyclingPlus automatically uses macOS system proxy settings
- Configure proxy in System Settings → Network → Proxies
- Always add localhost to proxy bypass list
- Test with Safari first to verify proxy works
- Be patient - proxies add latency to connections
- Check Console.app logs if you encounter issues

For additional troubleshooting, see [CONNECTION_TROUBLESHOOTING.md](CONNECTION_TROUBLESHOOTING.md)
