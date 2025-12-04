# CyclingPlus

CyclingPlus 是一款基于 SwiftUI + SwiftData 的骑行数据中枢，支持 Strava/iGPSport 同步、文件导入、功率与心率分析，以及可选的 AI 洞察。

## 功能亮点
- 多来源同步：Strava OAuth（ASWebAuthenticationSession，scheme `cyclingplus://cyclingplus`）、iGPSport 账号登录；全量/最近同步、进度提示、Keychain 存储凭据、重复检测与流数据回填。
- 活动管理：列表搜索/过滤/排序/批量删除，空状态可生成示例活动。
- 详细分析：概览、功率/心率区间、MMP、训练负荷，图表视图（功率/心率/速度/海拔），AI 摘要与建议，地图占位。
- 文件导入：拖拽或选择 GPX/TCX/FIT，展示进度与错误明细。
- 用户画像与偏好：体重、FTP、最大心率、区间计算；单位制、自动同步频率、隐私级别配置。
- AI 分析：默认本地启发式分析，可配置 DeepSeek/OpenAI/Claude API Key 触发云端精炼。
- 存储：SwiftData 本地库，位于 App Support（macOS 默认 `~/Library/Application Support/cyclingplus.store`，iOS 位于沙盒）；SampleDataService 提供示例数据。

## 开发环境
- Xcode 15.4+，Swift 5.10+。
- 目标平台：macOS 14+/iOS 17+（SwiftData/最新 SwiftUI 需此版本）。
- 无额外第三方依赖；需允许访问 Strava、iGPSport 与可选 AI 提供商网络。

## 快速开始
1. 打开 `cyclingplus.xcodeproj`，选择 `cyclingplus` target 及目标平台的设备/模拟器。
2. 配置 Signing Team、Bundle Identifier。
3. 运行（`⌘R`）即可启动；`⌘U` 可运行现有单元测试。

## 数据源配置
- Strava  
  - 在 Strava API 页面将 Authorization Callback Domain 设为 `cyclingplus`（详见 `STRAVA_连接说明_最终版.md`）。  
  - 应用内：Settings → Data Sources → Strava → Configure API Credentials，输入 Client ID 与 Client Secret（Keychain 持久化），再点击 Connect。
- iGPSport  
  - 应用内：Settings → Data Sources → iGPSport，使用账号密码登录；凭据加密保存于 Keychain。
- 同步  
  - 工具栏/菜单提供 Sync All、单服务同步与手动刷新；实时显示进度与错误，并按时间/距离/时长容差进行重复检测。

## AI 分析
- 路径：Settings → Analysis → AI Analysis。
- 可开关本地分析，选择 Provider（DeepSeek/OpenAI/Claude），并填写对应 API Key（存于用户偏好）。
- 未填写 Key 时仅使用本地启发式分析；填写后将尝试云端精炼，失败会自动回退到本地结果。

## 文件导入
- 打开 Import Activities（界面支持拖拽），或在空状态点击导入。
- 支持 GPX/TCX/FIT，多选导入；展示进度、成功数量与错误列表。
- 若无数据，可在空状态点击 “Create Sample Activity” 生成示例活动。

## 目录结构
- `cyclingplusApp.swift`：应用入口与 SwiftData 容器配置。
- `Models/`：活动、流数据、分析结果、用户画像与偏好等 SwiftData 模型。
- `Services/`：Strava/iGPSport 同步与认证、文件解析、功率/心率/AI 分析、数据仓库、网络权限等。
- `Views/`：SwiftUI 界面（列表、详情、设置、导入、诊断、组件、图表）。
- `cyclingplusTests/`：功率分析等单元测试。

## 调试与测试
- 单元测试：`xcodebuild test -scheme cyclingplus -destination 'platform=macOS,arch=arm64'` 或在 Xcode 使用 `⌘U`。
- 网络调试：Settings → Diagnostics → Network Diagnostics 可查看当前网络可用性。
- 数据清理：SwiftData 库位于 App Support，必要时可备份/删除该文件后重新启动应用（慎用）。

## 备注
- URL Scheme 默认 `cyclingplus://cyclingplus`，确保授权回调与 Strava 配置一致。
- 如出现授权或同步失败，优先检查网络权限、凭据正确性及 Strava/iGPSport 服务状态。提交 issue 时附上控制台日志有助于定位。
