# Requirements Document

## Introduction

本功能解决 CyclingPlus 应用在使用系统代理时遇到的 "Operation not permitted" (NSPOSIXErrorDomain Code=1) 错误。该错误是由于应用启用了 App Sandbox 但缺少网络权限声明导致的。应用需要创建 entitlements 文件并配置正确的网络权限，使其能够在系统代理环境下正常访问 Strava API。

## Glossary

- **AppSandbox**: macOS 应用沙盒安全机制，限制应用的系统访问权限
- **Entitlements**: macOS 应用权限配置文件，声明应用需要的系统权限
- **NetworkClient**: 网络客户端权限，允许应用发起出站网络连接
- **SystemProxy**: macOS 系统级代理设置
- **URLSession**: Apple 提供的网络请求框架
- **StravaAPI**: Strava 的 RESTful API 服务

## Requirements

### Requirement 1

**User Story:** 作为用户，我希望应用能够在 App Sandbox 环境下访问网络，以便正常连接 Strava API

#### Acceptance Criteria

1. THE Entitlements SHALL 创建 entitlements 文件
2. THE Entitlements SHALL 启用出站网络连接权限（com.apple.security.network.client）
3. THE Entitlements SHALL 在 Xcode 项目中正确配置 entitlements 文件路径
4. THE Entitlements SHALL 同时支持 Debug 和 Release 构建配置

### Requirement 2

**User Story:** 作为用户，我希望应用能够自动使用系统代理设置，以便在配置代理后无需额外操作

#### Acceptance Criteria

1. THE URLSession SHALL 使用默认配置以自动继承系统代理设置
2. THE URLSession SHALL 不覆盖系统代理配置
3. WHEN 系统配置了代理，THE URLSession SHALL 自动通过代理发起所有网络请求
4. THE URLSession SHALL 支持 HTTP、HTTPS 和 SOCKS5 代理协议

### Requirement 3

**User Story:** 作为用户，我希望应用在网络请求失败时提供清晰的错误信息，以便排查问题

#### Acceptance Criteria

1. WHEN 网络请求失败时，THE Entitlements SHALL 捕获并显示详细错误信息
2. IF 错误代码为 NSPOSIXErrorDomain Code=1，THEN THE Entitlements SHALL 提示用户检查网络权限配置
3. THE Entitlements SHALL 在错误消息中包含可能的解决方案
4. THE Entitlements SHALL 记录网络错误到控制台供调试使用

### Requirement 4

**User Story:** 作为用户，我希望 Strava OAuth 认证流程能够在代理环境下正常工作，以便完成账号授权

#### Acceptance Criteria

1. WHEN 用户启动 OAuth 认证时，THE Entitlements SHALL 允许打开系统浏览器
2. THE Entitlements SHALL 允许应用接收 OAuth 回调 URL
3. WHEN 交换授权码时，THE Entitlements SHALL 允许 token 请求通过代理完成
4. THE Entitlements SHALL 允许刷新 token 的请求通过代理完成

### Requirement 5

**User Story:** 作为开发者，我希望能够验证网络权限配置是否正确，以便确认问题已解决

#### Acceptance Criteria

1. THE Entitlements SHALL 在应用启动时验证网络权限是否已授予
2. WHEN 网络权限缺失时，THE Entitlements SHALL 在控制台输出警告信息
3. THE Entitlements SHALL 提供测试网络连接的功能
4. WHEN 测试连接成功时，THE Entitlements SHALL 显示成功消息
