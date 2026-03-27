# ConnectMate

ConnectMate 是一款基于 AppKit 的原生 macOS 工具，用于批量化、自动化管理 App Store Connect 工作流。应用通过本机已安装的 `asc` CLI 与 App Store Connect API 交互，覆盖 API Key 管理、App 列表、构建版本、审核提审、TestFlight、内购、签名资产管理、日志与偏好设置等能力。

## 主要特性

- 原生三栏界面：左侧导航、中间列表、右侧详情，适配 macOS 13+
- `asc` CLI 异步调用：统一命令执行、结果解析、错误提示与日志落库
- 本地数据持久化：使用 GRDB + SQLite 缓存 App、Build、Tester、IAP、命令日志等数据
- 设置中心完整可配：主题、语言、CLI 路径、缓存、通知、快捷键、更新策略
- 多语言：简体中文、繁体中文、英文
- 主题模式：跟随系统 / 浅色 / 深色
- Sparkle 自动更新：预留 `appcast.xml` 与发布脚本
- 发布链路已验证：Release 归档、Developer ID 重签、DMG 生成、公证、stapler

## 技术栈

- Swift
- AppKit
- SnapKit
- GRDB
- Sparkle 2.x
- CocoaPods
  - LookinServer（Debug）
  - ViewScopeServer（Debug）

## 环境要求

- macOS 13 或更高版本
- Xcode 17 或更高版本
- CocoaPods
- 已安装 `asc` CLI，默认路径 `/usr/local/bin/asc`
- 发布时需要：
  - `Developer ID Application` 证书
  - `notarytool` Keychain Profile
  - 全局可执行脚本 `create_pretty_dmg.sh`

## 本地开发

1. 安装依赖：

```bash
bundle exec pod install
```

2. 打开工程：

```bash
open ConnectMate.xcworkspace
```

3. 调试运行：

- `Debug` 配置会启用 `LookinServer` 与 `ViewScopeServer`
- `Release` 配置用于正式打包与签名验证

## `asc` CLI 与 API Key 配置

ConnectMate 依赖 `asc` CLI 访问 App Store Connect。首次启动会检查 CLI 是否存在，不存在时会提示安装。

### CLI

- 默认路径：`/usr/local/bin/asc`
- 可在应用内「设置 -> CLI 与 API」中修改

### API Key

在 App Store Connect 后台创建 API Key 后，需要准备以下信息：

- `Key ID`
- `Issuer ID`
- `.p8` 私钥文件

其中 `Issuer ID` 可在 App Store Connect 后台的 API Key 页面查看。ConnectMate 会把 `.p8` 文件保存为安全作用域书签，避免应用重启后丢失访问权限。

若需要手动验证 CLI，可使用：

```bash
asc auth login \
  --name "MyKey" \
  --key-id "<KEY_ID>" \
  --issuer-id "<ISSUER_ID>" \
  --private-key "/path/to/AuthKey.p8"
```

## 构建与打包

### Release 构建

```bash
xcodebuild \
  -workspace ConnectMate.xcworkspace \
  -scheme ConnectMate \
  -configuration Release \
  -destination 'platform=macOS' \
  ARCHS='arm64 x86_64' \
  ONLY_ACTIVE_ARCH=NO \
  build
```

### 归档、签名、生成 DMG、公证

```bash
./scripts/build_release.sh
```

脚本行为：

- 归档 `Release` 双架构产物
- 自动解析工程 `DEVELOPMENT_TEAM` 对应的 `Developer ID Application`
- 对 App 与 Sparkle 嵌套代码重签名并补齐 secure timestamp
- 调用全局 `create_pretty_dmg.sh` 生成 DMG
- 使用 `notarytool` 提交公证并执行 `stapler`

打包完成后，脚本会输出：

- `APP_PATH`
- `DMG_PATH`

当前已验证产物示例：

- `build/ConnectMate.xcarchive/Products/Applications/ConnectMate.app`
- `build/dmg/ConnectMate_v1.0_1.dmg`

## GitHub Release 与 Sparkle

### 上传 GitHub Release

```bash
./scripts/publish_release.sh \
  --dmg build/dmg/ConnectMate_v1.0_1.dmg \
  --repo wangwanjie/ConnectMate \
  --tag v1.0.0 \
  --title "ConnectMate 1.0"
```

脚本会自动：

- 推断仓库地址
- 创建或更新 GitHub Release
- 上传 DMG 资源

### 生成 Sparkle Appcast

```bash
./scripts/generate_appcast.sh \
  --archive build/dmg/ConnectMate_v1.0_1.dmg \
  --repo wangwanjie/ConnectMate
```

说明：

- `appcast.xml` 默认位于仓库根目录
- `SUFeedURL` 已指向 `https://raw.githubusercontent.com/wangwanjie/ConnectMate/main/appcast.xml`
- 首次生成 appcast 前，需要先准备 Sparkle EdDSA 密钥；脚本会自动检查并提示

## 工程结构

```text
ConnectMate/
├── ConnectMate/
│   ├── App/
│   ├── Core/
│   ├── Modules/
│   ├── Resources/
│   └── Info.plist
├── ConnectMateTests/
├── ConnectMateUITests/
├── scripts/
├── Podfile
├── Podfile.lock
├── appcast.xml
└── ConnectMate.xcworkspace
```

## 已实现模块

- API Key 配置与连通性验证
- 我的 App
- 构建版本
- 提交审核
- TestFlight 管理
- 内购管理
- 证书、描述文件、设备、标识符管理
- 任务日志
- 偏好设置、主题、多语言、快捷键、关于窗口

## 说明

- Debug 辅助依赖仅在调试配置启用，不参与正式发布包
- 发布脚本已按本仓库当前工程配置适配，不依赖额外的 DMG 美化逻辑
- `AuthKey_*.p8` 等敏感文件不应提交到 Git 仓库
