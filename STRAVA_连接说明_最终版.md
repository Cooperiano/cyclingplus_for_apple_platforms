# Strava 连接说明 - 最终版

## ✅ 已完成的更新

应用现在使用 `ASWebAuthenticationSession` 来处理 OAuth 流程，这是 Apple 推荐的标准方式。

## 配置步骤

### 第一步：配置 Strava API

1. 访问 https://www.strava.com/settings/api
2. 找到你的应用（Client ID: ）
3. 在 **Authorization Callback Domain** 字段中输入：`cyclingplus`
4. 点击 "Update" 保存

### 第二步：在应用中配置凭据

1. 打开 CyclingPlus 应用
2. 进入 Settings → Data Sources → Strava
3. 点击 "Configure API Credentials"
4. 输入：
   - **Client ID**: `(从你的 Strava API 页面复制)`
   - **Client Secret**: (从你的 Strava API 页面复制)
5. 点击 "Save"

### 第三步：连接 Strava

1. 在应用中点击 **"Connect to Strava"**
2. 会弹出一个浏览器窗口显示 Strava 授权页面
3. 点击 **"授权"** 按钮
4. 授权成功后，浏览器窗口会自动关闭
5. 应用会自动完成认证并显示你的 Strava 账户信息

## 工作原理

- 使用 `ASWebAuthenticationSession` 在应用内打开浏览器
- Redirect URI: `cyclingplus://auth/strava`
- 授权完成后自动返回应用
- 无需手动复制授权码

## 验证连接成功

连接成功后，你会看到：
- ✅ 绿色的勾选图标
- "Connected to Strava" 文字
- 你的 Strava 用户名和位置信息

## 常见问题

**Q: 浏览器窗口没有弹出？**  
A: 确认你已经配置了 Client ID 和 Client Secret。

**Q: 授权后浏览器没有自动关闭？**  
A: 检查 Strava API 设置中的 Authorization Callback Domain 是否设置为 `cyclingplus`（不要包含 `://` 或其他前缀）。

**Q: 显示"Invalid redirect_uri"错误？**  
A: 确认 Strava API 设置中的 Authorization Callback Domain 是 `cyclingplus`，不是 `localhost` 或其他值。

## 技术细节

### 使用的技术
- `ASWebAuthenticationSession`: Apple 官方推荐的 OAuth 处理方式
- 自动处理回调和 URL scheme
- 安全的浏览器会话，与应用隔离

### URL Scheme 配置
- 已在 `Info.plist` 中注册 `cyclingplus://` URL scheme
- `StravaAuthManager` 使用 `cyclingplus://auth/strava` 作为 redirect URI
- `ASWebAuthenticationSession` 自动处理回调

### 与之前方案的区别
- ❌ 旧方案：使用 `NSWorkspace.shared.open()` 打开系统浏览器，需要手动复制授权码
- ✅ 新方案：使用 `ASWebAuthenticationSession` 在应用内打开浏览器，自动处理回调

## 调试信息

如果遇到问题，查看 Xcode 控制台会显示详细的日志：
```
🔐 Starting ASWebAuthenticationSession...
   Auth URL: https://www.strava.com/oauth/authorize?...
✅ Received callback URL: cyclingplus://auth/strava?code=...
🔐 StravaAuthManager: Processing callback URL
✅ Authorization code received: ...
🔄 Exchanging code for tokens...
🌐 Making token exchange request to Strava...
📡 HTTP Status: 200
✅ Token exchange successful
💾 Storing credentials...
👤 Fetching athlete profile...
✅ Authentication complete!
```

## 需要帮助？

如果按照以上步骤操作后仍然无法连接，请：
1. 检查 Xcode 控制台的错误信息
2. 确认 Strava API 设置已保存
3. 确认 Client ID 和 Client Secret 正确
4. 尝试重启应用

## 总结

✅ **使用 ASWebAuthenticationSession**  
✅ **自动处理 OAuth 回调**  
✅ **无需手动复制授权码**  
✅ **符合 Apple 官方最佳实践**  

现在可以开始使用了！
