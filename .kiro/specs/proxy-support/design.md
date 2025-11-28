# Design Document

## Overview

本设计文档描述如何为 CyclingPlus macOS 应用添加网络权限配置，解决 App Sandbox 环境下的 "Operation not permitted" 错误。通过创建 entitlements 文件并配置网络客户端权限，应用将能够自动使用系统代理访问 Strava API。

## Architecture

### 高层架构

```
┌─────────────────────────────────────────┐
│         CyclingPlus App                 │
│  ┌───────────────────────────────────┐  │
│  │   App Sandbox Container           │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │  Network Client Permission  │  │  │
│  │  │  (Entitlements)             │  │  │
│  │  └─────────────────────────────┘  │  │
│  │           ↓                        │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │  URLSession                 │  │  │
│  │  │  (Auto-uses System Proxy)   │  │  │
│  │  └─────────────────────────────┘  │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│      macOS System Proxy Settings        │
│  (System Preferences → Network)         │
└─────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│         Proxy Server                    │
│  (HTTP/HTTPS/SOCKS5)                    │
└─────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│         Strava API                      │
│  (www.strava.com)                       │
└─────────────────────────────────────────┘
```

### 关键设计决策

1. **使用 Entitlements 而非禁用 Sandbox**
   - 保持 App Sandbox 启用以符合 macOS 安全最佳实践
   - 通过 entitlements 明确声明所需权限
   - 符合 App Store 分发要求

2. **自动使用系统代理**
   - URLSession 默认配置会自动继承系统代理设置
   - 无需在应用内实现代理配置界面
   - 用户在系统设置中配置代理即可

3. **最小权限原则**
   - 仅添加必需的网络客户端权限
   - 不添加其他不必要的权限

## Components and Interfaces

### 1. Entitlements 文件

**文件路径**: `cyclingplus/cyclingplus.entitlements`

**内容结构**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App Sandbox -->
    <key>com.apple.security.app-sandbox</key>
    <true/>
    
    <!-- Network Client (Outgoing Connections) -->
    <key>com.apple.security.network.client</key>
    <true/>
    
    <!-- User Selected Files (Already configured) -->
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
</dict>
</plist>
```

**权限说明**:
- `com.apple.security.app-sandbox`: 启用 App Sandbox
- `com.apple.security.network.client`: 允许出站网络连接
- `com.apple.security.files.user-selected.read-only`: 保留现有的文件访问权限

### 2. Xcode 项目配置

**修改文件**: `cyclingplus.xcodeproj/project.pbxproj`

**配置项**:
```
CODE_SIGN_ENTITLEMENTS = cyclingplus/cyclingplus.entitlements
```

需要在以下两个构建配置中添加：
- Debug (3E9567372EBDD337007D031E)
- Release (3E9567382EBDD337007D031E)

### 3. URLSession 配置验证

**现有实现**: 
- `StravaAuthManager.swift` 使用 `URLSession.shared`
- `StravaAPIService.swift` 使用 `URLSession.shared`

**验证点**:
- `URLSession.shared` 默认使用 `URLSessionConfiguration.default`
- `URLSessionConfiguration.default` 自动继承系统代理设置
- 无需修改现有代码

### 4. 错误处理增强

**修改文件**: `cyclingplus/Models/CyclingPlusError.swift`

**新增错误类型**:
```swift
case networkPermissionDenied(String)
```

**错误处理逻辑**:
```swift
// 在 StravaAuthManager 和 StravaAPIService 中
catch {
    if let urlError = error as? URLError,
       urlError.code == .notConnectedToInternet {
        // 检查是否为权限问题
        if urlError.errorUserInfo[NSUnderlyingErrorKey] is POSIXError {
            throw CyclingPlusError.networkPermissionDenied(
                "网络权限被拒绝。请确保应用已配置网络权限。"
            )
        }
    }
    throw error
}
```

## Data Models

无需新增数据模型。现有的网络相关模型已足够：
- `StravaCredentials`: OAuth 凭据
- `StravaActivity`: 活动数据
- `StravaActivityStreams`: 活动流数据

## Error Handling

### 错误类型

1. **NSPOSIXErrorDomain Code=1**
   - 原因：缺少网络权限
   - 解决：添加 entitlements
   - 用户提示：「网络权限配置错误，请联系开发者」

2. **URLError.notConnectedToInternet**
   - 原因：网络不可达或代理配置错误
   - 解决：检查系统代理设置
   - 用户提示：「无法连接网络，请检查代理设置」

3. **URLError.timedOut**
   - 原因：代理服务器响应超时
   - 解决：检查代理服务器状态
   - 用户提示：「连接超时，请检查代理服务器」

### 错误处理流程

```
网络请求失败
    ↓
检查错误类型
    ↓
┌─────────────────────────────────────┐
│ NSPOSIXErrorDomain Code=1?          │
│ → 权限问题，显示配置错误提示         │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ URLError.notConnectedToInternet?    │
│ → 网络问题，提示检查代理设置         │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ URLError.timedOut?                  │
│ → 超时问题，提示检查代理服务器       │
└─────────────────────────────────────┘
    ↓
记录详细错误日志
```

## Testing Strategy

### 1. 权限验证测试

**测试场景**:
- 验证 entitlements 文件已正确添加到项目
- 验证构建配置中包含 entitlements 路径
- 验证应用签名包含网络权限

**测试方法**:
```bash
# 检查应用签名
codesign -d --entitlements - /path/to/cyclingplus.app

# 应该看到 com.apple.security.network.client = true
```

### 2. 系统代理测试

**测试场景**:
- 配置系统 HTTP 代理
- 配置系统 HTTPS 代理
- 配置系统 SOCKS5 代理

**测试步骤**:
1. 在系统设置中配置代理
2. 启动应用
3. 尝试连接 Strava
4. 验证请求通过代理完成

**验证方法**:
- 检查代理服务器日志
- 使用网络监控工具（如 Charles Proxy）
- 查看应用控制台日志

### 3. OAuth 流程测试

**测试场景**:
- 在代理环境下完成 OAuth 认证
- 验证 token 交换
- 验证 token 刷新

**测试步骤**:
1. 配置系统代理
2. 点击「连接 Strava」
3. 完成浏览器授权
4. 验证回调处理
5. 验证 token 获取

### 4. 错误处理测试

**测试场景**:
- 代理服务器不可达
- 代理认证失败
- 网络超时

**测试方法**:
- 配置错误的代理地址
- 配置错误的代理端口
- 配置需要认证的代理但不提供凭据

### 5. 回归测试

**测试场景**:
- 无代理环境下的正常功能
- 文件导入功能
- 活动同步功能

**验证点**:
- 所有现有功能正常工作
- 无代理时直连正常
- 有代理时通过代理正常

## Implementation Notes

### 1. Entitlements 文件创建

- 使用 Xcode 创建：File → New → File → Property List
- 命名为 `cyclingplus.entitlements`
- 放置在 `cyclingplus/` 目录下
- 添加到 cyclingplus target

### 2. 项目配置更新

- 在 Xcode 中选择 cyclingplus target
- Build Settings → Code Signing Entitlements
- 设置为 `cyclingplus/cyclingplus.entitlements`
- 确保 Debug 和 Release 都配置

### 3. 代码修改最小化

- 现有 URLSession 代码无需修改
- 仅增强错误处理逻辑
- 添加网络权限检查（可选）

### 4. 用户文档更新

需要更新以下文档：
- `QUICK_START.md`: 添加代理配置说明
- `CONNECTION_TROUBLESHOOTING.md`: 添加代理相关故障排除

### 5. 系统代理配置指南

为用户提供系统代理配置步骤：
1. 打开「系统设置」→「网络」
2. 选择当前网络连接
3. 点击「详细信息」
4. 选择「代理」标签
5. 配置代理服务器地址和端口
6. 如需认证，勾选「代理服务器需要密码」

## Security Considerations

### 1. 权限最小化

- 仅添加必需的网络客户端权限
- 不添加服务器权限（com.apple.security.network.server）
- 保持其他 sandbox 限制

### 2. 代理凭据安全

- 代理认证由系统处理
- 应用不存储代理密码
- 使用系统 Keychain 管理凭据

### 3. HTTPS 安全

- 所有 Strava API 请求使用 HTTPS
- 代理不影响 TLS/SSL 加密
- 证书验证由系统处理

### 4. App Store 合规

- Entitlements 配置符合 App Store 要求
- App Sandbox 保持启用
- 无需额外审核说明

## Performance Considerations

### 1. 代理延迟

- 代理会增加网络延迟
- 建议在 UI 中显示加载状态
- 设置合理的超时时间（30-60秒）

### 2. 连接池

- URLSession 自动管理连接池
- 代理连接会被复用
- 无需手动优化

### 3. 错误重试

- 实现指数退避重试策略
- 最多重试 3 次
- 避免频繁请求导致代理限流

## Deployment

### 1. 开发环境

- 在 Xcode 中直接运行
- 自动应用 entitlements
- 支持调试和日志

### 2. 测试环境

- 使用 Archive 构建
- 导出为 Development 版本
- 在测试设备上安装

### 3. 生产环境

- 使用 Archive 构建
- 导出为 App Store 或 Developer ID 版本
- 提交到 App Store 或直接分发

### 4. 版本兼容性

- 最低支持 macOS 26.1（当前配置）
- Entitlements 在所有 macOS 版本上兼容
- 系统代理功能在所有版本上可用
