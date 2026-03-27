# ConnectMate 1.0 Design

## Goal

构建一个可发布的 macOS 原生应用 `ConnectMate`，通过本机已安装的 `/usr/local/bin/asc` 与 App Store Connect 交互，完整覆盖以下模块并发布 `1.0`：

- API Key 配置
- 我的 App
- Builds
- Review Submission
- TestFlight
- IAP
- 全局任务日志
- 偏好设置
- 多语言
- 换肤
- Sparkle 自动更新
- GitHub Release + notarized DMG 发布链路

约束：

- 必须是纯 AppKit
- 所有布局使用 SnapKit
- 不使用 Storyboard/XIB
- 所有功能必须映射到 `asc` 的真实能力，不允许假按钮或仅 UI 占位
- 签名、公证、Sparkle、发布方式复用 `HostsEditor`
- DMG 创建与美化不内置在仓库脚本中，统一调用全局 `create_pretty_dmg.sh`

## Recommended Approach

采用“统一壳层 + 共享基础设施 + 模块顺序落地”的实现方式。

先完成以下横向能力：

- 主窗口与三栏容器
- 偏好设置
- 主题
- 多语言
- GRDB 数据库
- CLI 执行与解析
- 统一日志
- Sparkle 更新
- 发布脚本

再按以下顺序完成业务模块：

1. Apps
2. Builds
3. Review
4. TestFlight
5. IAP
6. Logs / About / release finish

原因：

- 所有业务模块都依赖同一套 `Process` 封装、错误处理、缓存策略、账号切换和日志系统
- 先稳定底层，再接功能模块，返工最少
- 便于真实联调和最终 `1.0` 发布

## Architecture

工程划分为 5 层。

### 1. App Shell

负责应用生命周期与顶层窗口结构：

- `App/AppDelegate.swift`
- `App/MainWindowController.swift`
- `Modules/Sidebar`
- 全局菜单、快捷键、关于窗口、首次启动引导

主界面使用三栏 `NSSplitViewController`：

- 左侧 `Sidebar`
- 中间模块列表区
- 右侧详情区

### 2. Shared Platform

负责跨模块复用的 UI 与平台能力：

- Toast
- Alert / Confirm dialog
- Empty state / Loading state
- 图标异步加载
- 导出面板
- 通知
- 可复用列表页骨架

### 3. Core Services

负责底层基础设施：

- `ASCCommandRunner`
- `ASCOutputParser`
- `DatabaseManager`
- 设置存储
- 任务日志
- 缓存策略
- Sparkle 更新封装
- 账号 profile 切换

### 4. Domain Modules

每个业务模块采用一致结构：

- `Views`
- `Controllers`
- `Services`
- `Persistence`
- `Models`

模块只依赖 `Core Services` 暴露的接口，不直接操作 `Process`。

### Apps / Builds 新建动作边界

`我的 App` 与 `构建版本` 需要补齐“写操作”入口，但仍沿用当前三栏架构：

- Apps 列表页右上角增加“创建 App”
- Builds 列表页右上角增加“添加版本”
- 菜单栏同步提供同名命令，调用同一套页面动作
- 表单通过 sheet 展示，不引入单独窗口

命令边界：

- `创建 App` 使用 `asc apps create`
- `添加版本` 使用 `asc versions create`
- CLI 参数拼装必须集中在服务层，请求模型由服务层定义，控制器只提交表单值并处理成功/失败回调

鉴于 `asc apps create` 的真实行为依赖 Apple web-session，而不是 API Key，创建 App 的表单需要明确提示这一前提，失败时直接展示 CLI 返回信息，不做误导性的“API Key 配置失败”二次包装。

成功路径：

- 创建 App 成功后立即触发 Apps 列表刷新
- 添加版本成功后立即触发当前 App 的 Builds 列表刷新
- 两个动作都要复用现有 Toast / Alert 和命令日志链路

### 签名资产模块边界

新增单独的“签名资产”模块，而不是把证书、设备、描述文件直接塞进创建 App 表单。

模块拆分：

- 标识符：`asc bundle-ids`
- 证书：`asc certificates`
- 设备：`asc devices`
- 描述文件：`asc profiles`

交互结构：

- 左侧 Sidebar 增加“签名资产”
- 中间列表页顶部使用 segmented control 在四类资产之间切换
- 右侧详情页根据当前资产类型展示字段与操作按钮

创建 App 表单同步改造：

- `Primary Locale` 改为下拉选择，不再手输
- `Bundle ID` 改为可搜索选择
- 表单内提供“新建标识符”入口，新建成功后回填到创建 App 表单

实现边界：

- 语言列表使用应用内置 catalogue，不依赖 CLI 动态接口
- Bundle ID / 证书 / 设备 / 描述文件列表走真实 CLI JSON 输出
- 标识符、证书、设备、描述文件的写操作分别映射到各自 CLI create / update / delete / revoke / download 命令
- 新模块先走实时读取，不强制写入本地缓存数据库，避免为签名资产引入额外 schema 返工

### 5. Release Tooling

负责：

- 版本号更新
- archive / export
- 签名与公证
- DMG 生成
- GitHub Release
- Sparkle `appcast.xml`

## File Structure

目标目录结构如下：

```text
ConnectMate/
├── App/
│   ├── AppDelegate.swift
│   ├── MainWindowController.swift
│   ├── MainSplitViewController.swift
│   └── AppThemeManager.swift
├── Core/
│   ├── CLI/
│   │   ├── ASCCommandRunner.swift
│   │   ├── ASCCommandConfiguration.swift
│   │   ├── ASCCommandResult.swift
│   │   ├── ASCOutputParser.swift
│   │   └── ASCError.swift
│   ├── Database/
│   │   ├── DatabaseManager.swift
│   │   ├── DatabaseMigrator.swift
│   │   └── Models/
│   ├── Logging/
│   │   ├── CommandLogRepository.swift
│   │   └── CommandLogRecord.swift
│   ├── Settings/
│   │   ├── AppSettings.swift
│   │   ├── SettingKey.swift
│   │   └── PreferencesModels.swift
│   ├── Tasking/
│   │   ├── TaskCenter.swift
│   │   └── TaskProgress.swift
│   └── Updater/
│       └── SparkleUpdater.swift
├── Modules/
│   ├── Sidebar/
│   ├── Apps/
│   ├── Builds/
│   ├── Review/
│   ├── TestFlight/
│   ├── InAppPurchase/
│   ├── Settings/
│   ├── Logs/
│   ├── About/
│   └── Common/
├── Resources/
│   ├── en.lproj/Localizable.strings
│   ├── zh-Hans.lproj/Localizable.strings
│   ├── zh-Hant.lproj/Localizable.strings
│   ├── Assets.xcassets
│   └── Info.plist
├── Scripts/
│   ├── build_release.sh
│   ├── publish_release.sh
│   └── generate_appcast.sh
└── appcast.xml
```

## Data Model

数据库采用“结构化字段 + 原始 JSON”双轨方案。

### Core Tables

- `api_keys`
  - `id`
  - `name`
  - `issuer_id`
  - `key_id`
  - `p8_path`
  - `profile_name`
  - `is_active`
  - `last_verified_at`
  - `last_validation_status`

- `apps`
  - `id`
  - `account_key_id`
  - `asc_id`
  - `name`
  - `bundle_id`
  - `sku`
  - `platform`
  - `app_state`
  - `icon_url`
  - `raw_json`
  - `cached_at`

- `builds`
  - `id`
  - `account_key_id`
  - `asc_id`
  - `app_asc_id`
  - `version`
  - `build_number`
  - `processing_state`
  - `uploaded_at`
  - `raw_json`
  - `cached_at`

- `review_submissions`
  - `id`
  - `account_key_id`
  - `submission_id`
  - `app_asc_id`
  - `version_id`
  - `build_id`
  - `status`
  - `raw_json`
  - `updated_at`

- `testers`
  - `id`
  - `account_key_id`
  - `tester_id`
  - `app_asc_id`
  - `email`
  - `first_name`
  - `last_name`
  - `invite_status`
  - `raw_json`
  - `cached_at`

- `beta_groups`
  - `id`
  - `account_key_id`
  - `group_id`
  - `app_asc_id`
  - `name`
  - `is_internal`
  - `raw_json`
  - `cached_at`

- `iap_products`
  - `id`
  - `account_key_id`
  - `iap_id`
  - `app_asc_id`
  - `product_id`
  - `reference_name`
  - `product_type`
  - `status`
  - `price_summary`
  - `raw_json`
  - `cached_at`

- `command_logs`
  - `id`
  - `command`
  - `arguments_json`
  - `stdout_text`
  - `stderr_text`
  - `exit_code`
  - `duration_ms`
  - `status`
  - `executed_at`

- `app_settings`
  - `key`
  - `value`
  - `updated_at`

必要时可补：

- `tester_group_links`
- `iap_localizations`
- `review_details`

### Data Isolation

- 所有缓存数据按激活 API Key 隔离
- 多账号切换时禁止复用上一个账号的缓存列表
- 日志保留全局，但命令上下文中记录使用的 profile / key

## CLI Mapping

ConnectMate 中所有真实操作都必须映射到已存在的 `asc` 命令。

### API Key

- `asc auth login`
- `asc auth status --validate`
- `asc auth switch`
- `asc auth doctor`

本地 UI 保存字段：

- 名称
- Issuer ID
- Key ID
- `.p8` 路径
- 是否激活

### Apps

- `asc apps list --output json`
- `asc apps view --id`

### Builds

- `asc builds list --app`
- `asc builds latest --app`
- `asc builds expire --build`
- `asc builds expire-all --app`

### Review

高层提审流程优先使用：

- `asc submit preflight`
- `asc submit create`
- `asc submit status`
- `asc submit cancel`

审核详情补充使用：

- `asc review details-for-version`
- `asc review details-create`
- `asc review details-update`
- `asc review submissions-*`
- `asc review items-*`

### TestFlight

- `asc testflight testers list`
- `asc testflight testers add`
- `asc testflight testers invite`
- `asc testflight testers remove`
- `asc testflight groups list`
- `asc testflight groups create`
- `asc testflight groups edit`
- `asc testflight groups delete`
- `asc testflight groups add-testers`
- `asc testflight groups remove-testers`
- `asc builds add-groups`
- `asc testflight distribution view`

### IAP

命令实际使用 `asc iap`，而不是文档草案中的 `inAppPurchases`：

- `asc iap list`
- `asc iap view`
- `asc iap create`
- `asc iap setup`
- `asc iap update`
- `asc iap delete`
- `asc iap submit`
- `asc iap localizations *`
- `asc iap pricing *`

若订阅组展示信息不足，则补用：

- `asc subscriptions`

## Command Execution Model

所有 CLI 调用通过 `ASCCommandRunner` 执行：

- 使用 `Process + Pipe`
- 全异步 `async/await`
- 可注入环境变量
- 支持超时取消
- 支持重试
- 支持自定义 `asc` 路径
- 所有命令执行结果统一进入日志表

命令执行链路：

`UI -> Module Service -> ASCCommandRunner -> asc -> ASCOutputParser -> GRDB/cache -> UI refresh`

运行时行为：

- 列表页默认“先展示缓存，再后台刷新”
- 手动刷新始终强制远程请求
- 配置为“不缓存”时仅记录日志，不写业务缓存
- 所有错误都保留原始 stderr 便于排查

## UI Design

### Main Window

三栏结构：

- 左栏：导航、账号切换、全局刷新
- 中栏：列表、搜索、筛选、批量操作
- 右栏：详情、状态、可执行操作

### Shared View States

所有模块复用以下基础状态组件：

- `LoadingView`
- `EmptyStateView`
- `ErrorStateView`
- `ToastManager`
- `ConfirmDialogHelper`

### Settings Window

设置窗口参考 `HostsEditor` 的分段偏好窗口实现，但按本项目扩展为：

- `General`
- `Appearance`
- `Notifications`
- `CLI & API`
- `Data & Cache`
- `Updates`
- `Shortcuts`
- `About`

#### General

- Login Item 开关
- 启动自动刷新
- 默认打开页面
- 批量操作确认提示

#### Appearance

- 跟随系统 / 浅色 / 深色
- 侧边栏图标风格
- 列表行高

#### Notifications

- 审核状态变更通知
- Build 处理完成通知
- TestFlight 邀请接受通知
- 系统通知 / Toast / Both

#### CLI & API

- `asc` 路径
- 命令超时
- 重试次数
- 代理开关和地址

#### Data & Cache

- 缓存有效期
- 清空缓存
- 日志保留天数
- 导出数据库 JSON

#### Updates

- 自动检查更新
- 检查频率
- 更新通道
- 立即检查更新

#### Shortcuts

- 显示/隐藏主窗口
- 刷新当前页
- 新建任务
- 切换主题

#### About

- 图标、版本、build
- 检查更新
- 反馈问题
- 致谢

## Theme and Localization

### Theme

主题管理参考 `HostsEditor`，但命名与职责对齐 `ConnectMate`：

- `system`
- `light`
- `dark`

使用 `NSApplication.appearance` 与 semantic colors 管理。

### Localization

初始支持：

- `en`
- `zh-Hans`
- `zh-Hant`

所有用户可见文案必须走本地化封装，避免散落硬编码字符串。

## Hotkeys

快捷键实现允许参考：

- `/Users/VanJay/Documents/Work/KuGou/iPad/kugouHD/src/Mac/Components/HotKey`

设计约束：

- 应用内快捷键使用标准 `NSMenuItem` / responder chain
- 全局显示/隐藏主窗口快捷键若采用 Carbon 注册方式，需封装为独立模块，不污染业务代码
- 快捷键录制、格式化、冲突提示应放在 `Modules/Settings/Shortcuts`
- 若系统级冲突检测无法稳定拿到完整信息，UI 必须明确提示“仅检测应用内冲突与常见系统组合”

## Error Handling

统一错误分三层：

- `UserPresentableError`
- `CLIExecutionError`
- `ParsingError`

策略：

- 可恢复错误用 toast
- 危险操作失败或配置错误用 alert/sheet
- 批量任务用任务面板显示逐项结果
- 命令行原始输出只放到日志页，不直接暴露为糟糕的主界面文案

## Background Tasks and Notifications

增加统一 `TaskCenter`：

- 跟踪当前执行任务
- 支持批量任务进度
- 可在列表页和日志页复用

通知使用 `UserNotifications`，不使用废弃的 `NSUserNotification`。

## First Launch

首次启动引导检查：

- `asc` 是否存在
- `asc version` 是否可运行
- API Key 是否已配置
- 数据库是否初始化成功
- 更新配置是否完整

若 `asc` 缺失，显示安装说明与自定义路径入口。

## Testing Strategy

由于无人值守，UI 测试不能依赖人工处理权限弹窗，因此采用“单元测试为主、UI 测试精简”的策略。

### Unit Tests

重点覆盖：

- `ASCCommandRunner`
- `ASCOutputParser`
- GRDB migrations
- 设置存储
- 模块 service 的命令参数构造
- 状态映射与缓存策略

### UI Tests

仅覆盖：

- 启动
- 侧边栏导航
- 设置窗口基础交互
- 空态 / 错误态
- 非权限敏感的模块流程

### Live Verification

使用当前环境中的：

- 本机 `asc`
- 当前仓库目录下的 `AuthKey_2RU28PXQS7.p8`

进行真实联调。

## Release Design

发布流程复用 `HostsEditor` 的签名、公证、Sparkle、GitHub Release 思路。

### Build and Notarization

- `xcodebuild archive`
- 导出签名后的 `.app`
- 使用与 `HostsEditor` 相同的团队、证书、公证配置
- `stapler validate` 验证产物

### DMG

仓库脚本不再内置 DMG 布局与美化逻辑，统一调用全局脚本：

```bash
dmg_path="$(create_pretty_dmg.sh --app-path \"./ConnectMate.app\" --dmg-name \"ConnectMate\" --append-version --append-build | awk -F': ' '/^DMG_PATH: / {print $2}' | tail -n 1)"
```

要求：

- 发布脚本从该命令读取绝对路径
- 失败时中止发布
- 不将 DMG 布局逻辑复制进仓库

### GitHub Release

- 使用现有 `origin` 对应仓库
- `gh` CLI 发布 release
- release notes 同时作为 Sparkle `appcast.xml` 的内联说明来源

### Sparkle

- 使用 Sparkle 2.x
- app 启动后后台检查更新
- 关于窗口中手动检查更新
- `appcast.xml` 提交到仓库

## Delivery Milestones

虽然目标是一个完整 `1.0`，实施上拆为以下串行里程碑：

1. 工程重建与依赖接入
2. App shell / settings / theme / localization / database / logging
3. Apps
4. Builds
5. Review
6. TestFlight
7. IAP
8. Updates / About / release scripts
9. 全量验证、签名、公证、发布 `1.0`

## Open Constraints

以下点在实现时必须持续验证：

- `asc` 不同命令的 JSON 结构是否稳定
- 当前 API Key 权限是否覆盖所有模块
- 全局快捷键注册是否在 macOS 13+ 上稳定
- Sparkle feed、公钥、GitHub release 资产命名是否与生成脚本一致
- UI 测试是否会因系统权限或网络波动而变脆弱

## Approval Outcome

本设计基于以下已确认前提：

- 目标是完成所有模块并发布 `1.0`
- 所有功能必须真实映射 `asc`
- 语言支持 `中文简体 + 繁体 + 英文`
- `bundle identifier` 使用现有工程中的 `cn.vanjay.ConnectMate`
- 签名、公证配置复用 `HostsEditor`
- GitHub 已配置 `origin`
- API Key 由当前目录中的 `.p8` 文件提供
