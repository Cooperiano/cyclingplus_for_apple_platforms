# Implementation Plan

- [x] 1. 创建和配置 Entitlements 文件
  - 在 `cyclingplus/` 目录下创建 `cyclingplus.entitlements` 文件
  - 添加 App Sandbox 权限声明
  - 添加网络客户端权限（`com.apple.security.network.client`）
  - 保留现有的用户文件访问权限
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 2. 配置 Xcode 项目使用 Entitlements
  - 修改 `cyclingplus.xcodeproj/project.pbxproj` 文件
  - 在 Debug 构建配置中添加 `CODE_SIGN_ENTITLEMENTS` 设置
  - 在 Release 构建配置中添加 `CODE_SIGN_ENTITLEMENTS` 设置
  - 验证 entitlements 文件路径正确
  - _Requirements: 1.3, 1.4_

- [x] 3. 增强网络错误处理
  - 修改 `cyclingplus/Models/CyclingPlusError.swift`
  - 添加 `networkPermissionDenied` 错误类型
  - 在 `StravaAuthManager.swift` 中添加权限错误检测逻辑
  - 在 `StravaAPIService.swift` 中添加权限错误检测逻辑
  - 提供用户友好的错误消息
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 4. 验证 URLSession 配置
  - 检查 `StravaAuthManager.swift` 中的 URLSession 使用
  - 检查 `StravaAPIService.swift` 中的 URLSession 使用
  - 确认使用 `URLSession.shared` 或 `URLSessionConfiguration.default`
  - 确认没有覆盖系统代理设置
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [x] 5. 添加网络权限验证功能
  - 在应用启动时检查网络权限
  - 在控制台输出权限状态日志
  - 提供测试网络连接的功能
  - 在连接成功时显示确认消息
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x] 6. 更新用户文档
  - 更新 `QUICK_START.md` 添加系统代理配置说明
  - 更新 `CONNECTION_TROUBLESHOOTING.md` 添加代理相关故障排除
  - 创建系统代理配置指南（macOS 系统设置步骤）
  - 添加常见代理问题的解决方案
  - _Requirements: 3.3_

- [ ] 7. 测试代理功能
  - 配置系统 HTTP 代理并测试连接
  - 配置系统 HTTPS 代理并测试连接
  - 配置系统 SOCKS5 代理并测试连接
  - 测试 OAuth 认证流程在代理环境下的工作
  - 测试错误场景（代理不可达、认证失败等）
  - 验证无代理环境下的正常功能
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 5.4_
