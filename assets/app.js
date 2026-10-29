/* ConnectMate 主页脚本：三语、三态主题、窗口示意与滚动叙事、下载链接。 */
(function () {
  'use strict';

  var root = document.documentElement;
  var reduceMotion = matchMedia('(prefers-reduced-motion: reduce)');
  var REPO = 'wangwanjie/ConnectMate';

  // ---------- 文案 ----------
  var T = {
    'zh-Hans': {
      title: 'ConnectMate — 原生 macOS 的 App Store Connect 管理工具',
      desc: 'ConnectMate 是一款原生 macOS 工具，通过本机的 asc CLI 管理 App Store Connect：API Key、我的 App、构建版本与签名资产，三栏界面，命令可追溯。',
      iconAlt: 'ConnectMate 图标', navLabel: '页面导航', langLabel: '语言', themeLabel: '主题',
      themeLight: '浅色', themeDark: '深色', themeSystem: '跟随系统', ghLabel: 'GitHub 仓库',
      navStory: '工作流', navDetails: '细节', navStart: '开始使用', navDownload: '下载',
      eyebrow: 'ConnectMate · macOS 13 及更高版本',
      h1a: '把 App Store Connect', h1b: '装进一扇原生窗口。',
      lede: 'ConnectMate 通过本机的 asc CLI 管理 API Key、App、构建版本与签名资产。三栏界面，批量操作，每条命令都留有记录。',
      ctaDownload: '下载 ConnectMate', ctaStory: '看看怎么用',
      metaLine: '版本 {v} · Universal · {s} · 已签名并经 Apple 公证',
      s0n: '连接账号', s1n: '我的 App', s2n: '构建版本', s3n: '签名资产',
      s0k: '01 / API KEY', s0h: '拖入 .p8，<br>账号就绪。',
      s0p: '在 API Key 管理里填写 Issuer ID 与 Key ID，拖入 .p8 私钥，一键验证。可以保存多套配置并随时切换当前账号；私钥以安全作用域书签引用，文件留在原处。',
      s0c1: '多账号切换', s0c2: '连通性验证', s0c3: 'asc auth login',
      s1k: '02 / APPS', s1h: '所有 App，<br>一列看清。',
      s1p: '刷新一次，列表写入本地缓存，按名称或 Bundle ID 即时搜索；右侧详情列出 Bundle ID、SKU、App ID 与平台。新 App 也能在这里直接创建。',
      s1c1: '本地缓存', s1c2: '即时搜索', s1c3: '创建 App',
      s2k: '03 / BUILDS', s2h: '勾选几个，<br>一次过期。',
      s2p: '按 App 加载构建版本，处理中、有效、无效、已过期一目了然。多选后批量标记过期，进度显示在后台任务里；要发新版时，直接添加 App Store 版本。',
      s2c1: '批量标记过期', s2c2: '添加版本', s2c3: '后台任务进度',
      s3k: '04 / SIGNING', s3h: '证书与描述文件，<br>不必再开网页。',
      s3p: '标识符、证书、设备、描述文件集中在一处：生成 CSR 并创建证书，用当前 Mac 的 UDID 注册设备，从列表勾选 Bundle ID、证书和设备创建描述文件，下载或删除点一下即可。',
      s3c1: '生成 CSR', s3c2: '注册设备', s3c3: '配置标识符能力',
      winAlt: 'ConnectMate 主窗口示意：左侧导航、中间列表、右侧详情', winNote: '界面示意，图中 App 与数据均为虚构示例。',
      detK: 'DETAILS', detH: '安静做事，留下记录。', detP: '这些细节让日常的 App Store Connect 杂务少一点意外。',
      c1h: '命令日志', c1p: '每条 asc 命令连同参数、输出、退出码与耗时写入本地数据库，可从「文件」菜单导出。',
      c2h: '本地缓存', c2p: 'App、构建版本等数据缓存在本机 SQLite。有效期可选 5 分钟、30 分钟、1 小时或手动刷新，也可一键清除，配置保留。',
      c3h: '导出所有数据', c3p: 'API Key 配置、缓存的 App 与构建版本、命令日志，一并导出为 JSON 备份，保存位置自选。',
      c4h: '三语与三种外观', c4p: '简体中文、繁体中文、英文界面；跟随系统、浅色、深色三种主题，侧边栏样式与列表行高也可调。',
      c5h: '快捷键与代理', c5p: '可录制全局快捷键与刷新快捷键；为 asc 设置 HTTP 代理、命令超时与重试次数。',
      c6h: '自动更新', c6p: '内置 Sparkle，更新包经 EdDSA 签名校验；可设置检查频率，也能随时手动检查。',
      stK: 'GET STARTED', stH: '三步开始。', stP: 'ConnectMate 依赖本机的 asc CLI 与一把 App Store Connect API Key。',
      t1h: '安装 asc CLI', t1p: '按 <a href="https://github.com/rudrankriyam/App-Store-Connect-CLI">App Store Connect CLI</a> 项目说明安装。默认路径 <code>/usr/local/bin/asc</code>，可在「设置 → CLI 与 API」中修改；首次启动会自动检查。',
      t2h: '准备 API Key', t2p: '在 App Store Connect 后台创建 API Key，记下 Issuer ID 与 Key ID，并下载 .p8 私钥文件。',
      t3h: '拖入并验证', t3p: '打开「管理 API Key」，拖入 .p8、填好信息后点击验证，再刷新「我的 App」即可开始。',
      dlH: '下载 ConnectMate', fVer: '版本', fSys: '系统要求', fSysV: 'macOS 13 或更高', fArch: '架构', fArchV: 'Universal（Apple 芯片 + Intel）',
      fSign: '签名', fSignV: 'Developer ID · 已公证', dlBtn: '下载 DMG', dlAll: '全部版本', sizeFmt: '· {s}',
      dlNote: '打开 DMG，把 ConnectMate 拖进「应用程序」文件夹。之后的新版本会在应用内通过 Sparkle 提示更新。',
      pvH: '隐私',
      pvP1: 'ConnectMate 没有账号系统，也不内置统计 SDK。API Key 配置、缓存与命令日志保存在本机 <code>~/Library/Application Support/ConnectMate</code>，对 App Store Connect 的访问全部经由本机的 asc CLI 完成。',
      pvP2: '检查更新时，应用会向 GitHub 请求更新源与 Release 信息；Sparkle 可能随请求附带匿名系统信息（如 macOS 版本）。',
      ftMore: 'VanJay 的更多作品 ›', ftRepo: 'GitHub 仓库', ftIssues: '反馈问题', ftReleases: '发布记录',
      // 窗口示意
      sb: ['我的 App', '构建版本', '提交审核', 'TestFlight', '内购管理', '签名资产', '设置', '任务日志'],
      wApps: '我的 App', wRefresh: '刷新', wCreate: '创建 App', wSearch: '搜索 App 名称或 Bundle ID',
      wBuilds: '构建版本', wAddVer: '添加版本', wExpire: '批量标记过期',
      wVer: '版本号', wBuildNo: 'Build 号', wStatus: '状态', wUploaded: '上传时间', wPlatform: '平台', wExpired: '是否过期', wNo: '否',
      stValid: '有效', stProc: '处理中', stExp: '已过期', stInvalid: '无效',
      wSigning: '签名资产', wSegs: ['标识符', '证书', '设备', '描述文件'], wType: '类型', wPState: '描述文件状态', wExpire2: '到期时间',
      wDownload: '下载', wDelete: '删除', wName: '名称', wPrimary: '主语言', wCached: '缓存时间', wCachedV: '刚刚',
      kTitle: 'API Key 管理', kDrop: '拖入 .p8 文件，或点击选择', kName: '配置名称', kValidate: '验证', kSave: '保存',
      kOk: '验证成功，凭据可用于 App Store Connect。', kActive: '当前使用',
      task: '后台任务进行中：1', taskIdle: '当前没有后台任务',
      o0: '<em>✓</em> 已登录 · 配置 Studio 设为当前账号', o1: '<em>✓</em> 6 个 App · 已写入本地缓存',
      o2: '<em>✓</em> 2/2 · 已将所选构建版本标记为过期', o3: '<em>✓</em> 已下载 Aurora_Notes_AppStore.mobileprovision'
    },
    'zh-Hant': {
      title: 'ConnectMate — 原生 macOS 的 App Store Connect 管理工具',
      desc: 'ConnectMate 是一款原生 macOS 工具，透過本機的 asc CLI 管理 App Store Connect：API Key、我的 App、建置版本與簽名資產，三欄介面，命令可追溯。',
      iconAlt: 'ConnectMate 圖示', navLabel: '頁面導覽', langLabel: '語言', themeLabel: '主題',
      themeLight: '淺色', themeDark: '深色', themeSystem: '跟隨系統', ghLabel: 'GitHub 儲存庫',
      navStory: '工作流程', navDetails: '細節', navStart: '開始使用', navDownload: '下載',
      eyebrow: 'ConnectMate · macOS 13 及更新版本',
      h1a: '把 App Store Connect', h1b: '裝進一扇原生視窗。',
      lede: 'ConnectMate 透過本機的 asc CLI 管理 API Key、App、建置版本與簽名資產。三欄介面，批次操作，每條命令都留有紀錄。',
      ctaDownload: '下載 ConnectMate', ctaStory: '看看怎麼用',
      metaLine: '版本 {v} · Universal · {s} · 已簽名並經 Apple 公證',
      s0n: '連接帳號', s1n: '我的 App', s2n: '建置版本', s3n: '簽名資產',
      s0k: '01 / API KEY', s0h: '拖入 .p8，<br>帳號就緒。',
      s0p: '在 API Key 管理裡填寫 Issuer ID 與 Key ID，拖入 .p8 私鑰，一鍵驗證。可以儲存多組設定並隨時切換目前帳號；私鑰以安全範圍書籤引用，檔案留在原處。',
      s0c1: '多帳號切換', s0c2: '連線驗證', s0c3: 'asc auth login',
      s1k: '02 / APPS', s1h: '所有 App，<br>一欄看清。',
      s1p: '重新整理一次，列表寫入本機快取，依名稱或 Bundle ID 即時搜尋；右側詳細資訊列出 Bundle ID、SKU、App ID 與平台。新 App 也能在這裡直接建立。',
      s1c1: '本機快取', s1c2: '即時搜尋', s1c3: '建立 App',
      s2k: '03 / BUILDS', s2h: '勾選幾個，<br>一次過期。',
      s2p: '依 App 載入建置版本，處理中、有效、無效、已過期一目了然。多選後批次標記過期，進度顯示在背景任務裡；要發新版時，直接新增 App Store 版本。',
      s2c1: '批次標記過期', s2c2: '新增版本', s2c3: '背景任務進度',
      s3k: '04 / SIGNING', s3h: '憑證與描述檔，<br>不必再開網頁。',
      s3p: '識別符、憑證、裝置、描述檔集中在一處：產生 CSR 並建立憑證，用目前 Mac 的 UDID 註冊裝置，從列表勾選 Bundle ID、憑證和裝置建立描述檔，下載或刪除點一下即可。',
      s3c1: '產生 CSR', s3c2: '註冊裝置', s3c3: '設定識別符功能',
      winAlt: 'ConnectMate 主視窗示意：左側導覽、中間列表、右側詳細資訊', winNote: '介面示意，圖中 App 與資料皆為虛構範例。',
      detK: 'DETAILS', detH: '安靜做事，留下紀錄。', detP: '這些細節讓日常的 App Store Connect 雜務少一點意外。',
      c1h: '命令日誌', c1p: '每條 asc 命令連同參數、輸出、結束代碼與耗時寫入本機資料庫，可從「檔案」選單匯出。',
      c2h: '本機快取', c2p: 'App、建置版本等資料快取在本機 SQLite。有效期可選 5 分鐘、30 分鐘、1 小時或手動重新整理，也可一鍵清除，設定保留。',
      c3h: '匯出所有資料', c3p: 'API Key 設定、快取的 App 與建置版本、命令日誌，一併匯出為 JSON 備份，儲存位置自選。',
      c4h: '三種語言與三種外觀', c4p: '簡體中文、繁體中文、英文介面；跟隨系統、淺色、深色三種主題，側邊欄樣式與列表列高也可調整。',
      c5h: '快捷鍵與代理', c5p: '可錄製全域快捷鍵與重新整理快捷鍵；為 asc 設定 HTTP 代理、命令逾時與重試次數。',
      c6h: '自動更新', c6p: '內建 Sparkle，更新套件經 EdDSA 簽名驗證；可設定檢查頻率，也能隨時手動檢查。',
      stK: 'GET STARTED', stH: '三步開始。', stP: 'ConnectMate 需要本機的 asc CLI 與一把 App Store Connect API Key。',
      t1h: '安裝 asc CLI', t1p: '依 <a href="https://github.com/rudrankriyam/App-Store-Connect-CLI">App Store Connect CLI</a> 專案說明安裝。預設路徑 <code>/usr/local/bin/asc</code>，可在「設定 → CLI 與 API」中修改；首次啟動會自動檢查。',
      t2h: '準備 API Key', t2p: '在 App Store Connect 後台建立 API Key，記下 Issuer ID 與 Key ID，並下載 .p8 私鑰檔案。',
      t3h: '拖入並驗證', t3p: '打開「管理 API Key」，拖入 .p8、填好資訊後點一下驗證，再重新整理「我的 App」即可開始。',
      dlH: '下載 ConnectMate', fVer: '版本', fSys: '系統需求', fSysV: 'macOS 13 或更新版本', fArch: '架構', fArchV: 'Universal（Apple 晶片 + Intel）',
      fSign: '簽名', fSignV: 'Developer ID · 已公證', dlBtn: '下載 DMG', dlAll: '所有版本', sizeFmt: '· {s}',
      dlNote: '打開 DMG，把 ConnectMate 拖進「應用程式」資料夾。之後的新版本會在 App 內透過 Sparkle 提示更新。',
      pvH: '隱私權',
      pvP1: 'ConnectMate 沒有帳號系統，也不內建統計 SDK。API Key 設定、快取與命令日誌儲存在本機 <code>~/Library/Application Support/ConnectMate</code>，對 App Store Connect 的存取全部經由本機的 asc CLI 完成。',
      pvP2: '檢查更新時，App 會向 GitHub 請求更新來源與 Release 資訊；Sparkle 可能隨請求附帶匿名系統資訊（如 macOS 版本）。',
      ftMore: 'VanJay 的更多作品 ›', ftRepo: 'GitHub 儲存庫', ftIssues: '回報問題', ftReleases: '發布紀錄',
      sb: ['我的 App', '建置版本', '提交審核', 'TestFlight', 'App 內購買', '簽名資產', '設定', '任務日誌'],
      wApps: '我的 App', wRefresh: '重新整理', wCreate: '建立 App', wSearch: '搜尋 App 名稱或 Bundle ID',
      wBuilds: '建置版本', wAddVer: '新增版本', wExpire: '批次標記過期',
      wVer: '版本號', wBuildNo: 'Build 號', wStatus: '狀態', wUploaded: '上傳時間', wPlatform: '平台', wExpired: '是否過期', wNo: '否',
      stValid: '有效', stProc: '處理中', stExp: '已過期', stInvalid: '無效',
      wSigning: '簽名資產', wSegs: ['識別符', '憑證', '裝置', '描述檔'], wType: '類型', wPState: '描述檔狀態', wExpire2: '到期時間',
      wDownload: '下載', wDelete: '刪除', wName: '名稱', wPrimary: '主要語言', wCached: '快取時間', wCachedV: '剛剛',
      kTitle: 'API Key 管理', kDrop: '拖入 .p8 檔案，或點一下選擇', kName: '設定名稱', kValidate: '驗證', kSave: '儲存',
      kOk: '驗證成功，憑證可用於 App Store Connect。', kActive: '目前使用',
      task: '背景任務進行中：1', taskIdle: '目前沒有背景任務',
      o0: '<em>✓</em> 已登入 · 設定 Studio 設為目前帳號', o1: '<em>✓</em> 6 個 App · 已寫入本機快取',
      o2: '<em>✓</em> 2/2 · 已將所選建置版本標記為過期', o3: '<em>✓</em> 已下載 Aurora_Notes_AppStore.mobileprovision'
    },
    en: {
      title: 'ConnectMate — a native macOS app for App Store Connect',
      desc: 'ConnectMate is a native macOS app that manages App Store Connect through your local asc CLI: API keys, apps, builds and signing assets in a three-pane window, with every command logged.',
      iconAlt: 'ConnectMate icon', navLabel: 'Page navigation', langLabel: 'Language', themeLabel: 'Theme',
      themeLight: 'Light', themeDark: 'Dark', themeSystem: 'Match system', ghLabel: 'GitHub repository',
      navStory: 'Workflow', navDetails: 'Details', navStart: 'Get started', navDownload: 'Download',
      eyebrow: 'ConnectMate · macOS 13 or later',
      h1a: 'App Store Connect,', h1b: 'in one native window.',
      lede: 'ConnectMate drives your local asc CLI to manage API keys, apps, builds and signing assets. Three panes, batch actions, and a log of every command it runs.',
      ctaDownload: 'Download ConnectMate', ctaStory: 'See how it works',
      metaLine: 'Version {v} · Universal · {s} · Signed and notarized by Apple',
      s0n: 'Connect', s1n: 'My Apps', s2n: 'Builds', s3n: 'Signing',
      s0k: '01 / API KEY', s0h: 'Drop in a .p8.<br>You’re connected.',
      s0p: 'Enter the Issuer ID and Key ID, drop in the .p8 private key and validate with one click. Save several profiles and switch the active account any time; the key is referenced through a security-scoped bookmark and stays where you keep it.',
      s0c1: 'Multiple accounts', s0c2: 'Connection check', s0c3: 'asc auth login',
      s1k: '02 / APPS', s1h: 'Every app,<br>in one column.',
      s1p: 'Refresh once and the list is cached locally, searchable by name or bundle ID as you type. The detail pane shows the bundle ID, SKU, App ID and platform. You can create new apps right here too.',
      s1c1: 'Local cache', s1c2: 'Instant search', s1c3: 'Create App',
      s2k: '03 / BUILDS', s2h: 'Select a few.<br>Expire them at once.',
      s2p: 'Load builds per app and see processing, valid, invalid and expired at a glance. Multi-select and expire them in one go while progress shows up in background tasks. Ready to ship? Add a new App Store version from the same pane.',
      s2c1: 'Batch expire', s2c2: 'Add version', s2c3: 'Background tasks',
      s3k: '04 / SIGNING', s3h: 'Certificates and profiles,<br>no browser needed.',
      s3p: 'Identifiers, certificates, devices and profiles in one place: generate a CSR and create a certificate, register this Mac by its UDID, pick bundle IDs, certificates and devices from lists to create a profile, then download or delete it with a click.',
      s3c1: 'Generate CSR', s3c2: 'Register devices', s3c3: 'Identifier capabilities',
      winAlt: 'Illustration of the ConnectMate main window: sidebar, list and detail panes', winNote: 'Illustration only. Apps and data shown are fictional examples.',
      detK: 'DETAILS', detH: 'Quiet work, on the record.', detP: 'Small things that make everyday App Store Connect chores less surprising.',
      c1h: 'Command log', c1p: 'Every asc command is stored locally with its arguments, output, exit code and duration, and can be exported from the File menu.',
      c2h: 'Local cache', c2p: 'Apps, builds and more are cached in a local SQLite database. Keep them 5 minutes, 30 minutes, an hour or until you refresh, and clear the cache in one click without touching settings.',
      c3h: 'Export everything', c3p: 'API key profiles, cached apps and builds, and command logs export together as a JSON backup to a location you choose.',
      c4h: 'Three languages, three looks', c4p: 'Simplified Chinese, Traditional Chinese and English. Match system, light or dark, plus adjustable sidebar style and row height.',
      c5h: 'Shortcuts and proxy', c5p: 'Record a global shortcut and a refresh shortcut. Give asc an HTTP proxy, a command timeout and a retry count.',
      c6h: 'Automatic updates', c6p: 'Built on Sparkle with EdDSA-signed updates. Choose how often to check, or check by hand any time.',
      stK: 'GET STARTED', stH: 'Three steps to start.', stP: 'ConnectMate needs the asc CLI on your Mac and an App Store Connect API key.',
      t1h: 'Install the asc CLI', t1p: 'Follow the <a href="https://github.com/rudrankriyam/App-Store-Connect-CLI">App Store Connect CLI</a> instructions. The default path is <code>/usr/local/bin/asc</code>; change it under Settings → CLI &amp; API. ConnectMate checks for it on first launch.',
      t2h: 'Create an API key', t2p: 'Create an API key in App Store Connect, note the Issuer ID and Key ID, and download the .p8 private key.',
      t3h: 'Drop it in and validate', t3p: 'Open Manage API Keys, drop in the .p8, fill in the details and click Validate. Then refresh My Apps and you’re set.',
      dlH: 'Download ConnectMate', fVer: 'Version', fSys: 'Requires', fSysV: 'macOS 13 or later', fArch: 'Architecture', fArchV: 'Universal (Apple silicon + Intel)',
      fSign: 'Signing', fSignV: 'Developer ID · Notarized', dlBtn: 'Download DMG', dlAll: 'All releases', sizeFmt: '· {s}',
      dlNote: 'Open the DMG and drag ConnectMate into Applications. Future versions are offered in the app through Sparkle.',
      pvH: 'Privacy',
      pvP1: 'ConnectMate has no accounts and no analytics SDK. API key profiles, cache and command logs stay on your Mac in <code>~/Library/Application Support/ConnectMate</code>, and all App Store Connect access goes through your local asc CLI.',
      pvP2: 'When checking for updates, the app requests the update feed and release information from GitHub; Sparkle may include anonymous system information such as the macOS version.',
      ftMore: 'More from VanJay ›', ftRepo: 'GitHub repository', ftIssues: 'Report an issue', ftReleases: 'Releases',
      sb: ['My Apps', 'Builds', 'Review', 'TestFlight', 'In-App Purchases', 'Signing Assets', 'Settings', 'Logs'],
      wApps: 'My Apps', wRefresh: 'Refresh', wCreate: 'Create App', wSearch: 'Search apps or bundle IDs',
      wBuilds: 'Builds', wAddVer: 'Add Version', wExpire: 'Expire Selected',
      wVer: 'Version', wBuildNo: 'Build', wStatus: 'Status', wUploaded: 'Uploaded', wPlatform: 'Platform', wExpired: 'Expired', wNo: 'No',
      stValid: 'Valid', stProc: 'Processing', stExp: 'Expired', stInvalid: 'Invalid',
      wSigning: 'Signing Assets', wSegs: ['Identifiers', 'Certificates', 'Devices', 'Profiles'], wType: 'Type', wPState: 'Profile State', wExpire2: 'Expires',
      wDownload: 'Download', wDelete: 'Delete', wName: 'Name', wPrimary: 'Primary Locale', wCached: 'Cached', wCachedV: 'Just now',
      kTitle: 'API Keys', kDrop: 'Drop a .p8 file here or click to choose one', kName: 'Profile Name', kValidate: 'Validate', kSave: 'Save',
      kOk: 'Validation succeeded. These credentials work with App Store Connect.', kActive: 'Active',
      task: 'Background tasks running: 1', taskIdle: 'No background tasks',
      o0: '<em>✓</em> Logged in · profile Studio is now active', o1: '<em>✓</em> 6 apps · written to local cache',
      o2: '<em>✓</em> 2/2 · selected builds marked as expired', o3: '<em>✓</em> Downloaded Aurora_Notes_AppStore.mobileprovision'
    }
  };

  var lang = root.lang in T ? root.lang : 'zh-Hans';
  var t = function (k) {
    return T[lang][k];
  };

  // 下载信息：先用已知的 v1.0 数据，GitHub API 返回后替换
  var release = { version: '1.0', size: '6.5 MB', url: 'https://github.com/' + REPO + '/releases/latest' };

  function fmt(s) {
    return s.replace('{v}', release.version).replace('{s}', release.size);
  }

  function applyLang(next, save) {
    lang = next in T ? next : 'zh-Hans';
    root.lang = lang;
    if (save) {
      localStorage.setItem('cm-lang', lang);
    }
    document.title = t('title');
    document.querySelector('meta[name="description"]').content = t('desc');
    document.querySelector('meta[property="og:title"]').content = t('title');
    document.querySelector('meta[property="og:description"]').content = t('desc');
    document.querySelectorAll('[data-i18n]').forEach(function (el) {
      var v = t(el.dataset.i18n);
      if (v != null) {
        el.textContent = el.dataset.i18n === 'metaLine' ? fmt(v) : v;
      }
    });
    document.querySelectorAll('[data-i18n-html]').forEach(function (el) {
      var v = t(el.dataset.i18nHtml);
      if (v != null) {
        el.innerHTML = v;
      }
    });
    document.querySelectorAll('[data-i18n-alt]').forEach(function (el) {
      el.alt = t(el.dataset.i18nAlt);
    });
    document.querySelectorAll('[data-i18n-aria]').forEach(function (el) {
      el.setAttribute('aria-label', t(el.dataset.i18nAria));
    });
    document.querySelectorAll('[data-size]').forEach(function (el) {
      el.textContent = t('sizeFmt').replace('{s}', release.size);
    });
    document.querySelectorAll('#langSeg button').forEach(function (b) {
      b.setAttribute('aria-pressed', String(b.dataset.lang === lang));
    });
    buildWindow();
    setStep(current, true);
  }

  // ---------- 主题 ----------
  var darkMQ = matchMedia('(prefers-color-scheme: dark)');

  function applyTheme(pref, save) {
    if (pref !== 'light' && pref !== 'dark') {
      pref = 'system';
    }
    root.dataset.pref = pref;
    var dark = pref === 'dark' || (pref === 'system' && darkMQ.matches);
    root.dataset.theme = dark ? 'dark' : 'light';
    document.querySelector('meta[name="theme-color"]').content = dark ? '#04050c' : '#fbfbfd';
    if (save) {
      localStorage.setItem('cm-theme', pref);
    }
    document.querySelectorAll('#themeSeg button').forEach(function (b) {
      b.setAttribute('aria-pressed', String(b.dataset.themeSet === pref));
    });
  }

  darkMQ.addEventListener('change', function () {
    if (root.dataset.pref === 'system') {
      applyTheme('system', false);
    }
  });

  document.getElementById('themeSeg').addEventListener('click', function (e) {
    var b = e.target.closest('button');
    if (b) {
      applyTheme(b.dataset.themeSet, true);
    }
  });

  document.getElementById('langSeg').addEventListener('click', function (e) {
    var b = e.target.closest('button');
    if (b) {
      applyLang(b.dataset.lang, true);
    }
  });

  // ---------- 窗口示意 ----------
  var ICONS = [
    '<rect x="4" y="4" width="16" height="16" rx="4"/><circle cx="18" cy="6" r="3" fill="currentColor" stroke="none"/>',
    '<path d="M4 8l8-4 8 4v8l-8 4-8-4z"/><path d="M4 8l8 4 8-4M12 12v8"/>',
    '<path d="M21 3L3 10.5l7 2.5 2.5 7z"/><path d="M10 13l11-10"/>',
    '<circle cx="12" cy="8" r="3"/><circle cx="5" cy="10" r="2.2"/><circle cx="19" cy="10" r="2.2"/><path d="M6.5 19c.6-3 2.8-4.5 5.5-4.5s4.9 1.5 5.5 4.5"/>',
    '<circle cx="12" cy="12" r="9"/><path d="M14.8 9.2c-.5-.9-1.6-1.4-2.8-1.4-1.6 0-2.8.8-2.8 2s1.2 1.7 2.8 2.1 2.9.9 2.9 2.2-1.3 2.1-2.9 2.1c-1.3 0-2.4-.6-2.9-1.5M12 6v1.8M12 16.2V18"/>',
    '<path d="M12 3l2.3 1.7 2.8-.2.9 2.7 2.3 1.6-.9 2.7.9 2.7-2.3 1.6-.9 2.7-2.8-.2L12 21l-2.3-1.7-2.8.2-.9-2.7-2.3-1.6.9-2.7-.9-2.7 2.3-1.6.9-2.7 2.8.2z"/><path d="M9 12l2 2 4-4"/>',
    '<circle cx="12" cy="12" r="3"/><path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.3 5.3l2.1 2.1M16.6 16.6l2.1 2.1M5.3 18.7l2.1-2.1M16.6 7.4l2.1-2.1"/>',
    '<path d="M4 6h16M4 10h16M4 14h16M4 18h16"/>'
  ];
  var APPS = [
    ['Aurora Notes', 'com.example.aurora', 'IOS', '#1c6cdf', '#6a2bbd'],
    ['Pixel Lab', 'com.example.pixellab', 'IOS', '#ff7a45', '#e0367a'],
    ['Tide Timer', 'com.example.tide', 'MAC_OS', '#13a8a0', '#1c6cdf'],
    ['Fieldbook', 'com.example.fieldbook', 'IOS', '#5aa64a', '#1f7a5c'],
    ['Lumen Reader', 'com.example.lumen', 'IOS', '#f2b632', '#e2702b'],
    ['Kilo', 'com.example.kilo', 'MAC_OS', '#4a4f6b', '#1b1e33']
  ];

  function svg(p) {
    return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">' + p + '</svg>';
  }

  function ic(a, size) {
    return '<span class="ic" style="background:linear-gradient(135deg,' + a[3] + ',' + a[4] + ')">' + a[0].charAt(0) + '</span>';
  }

  function tag(cls, text) {
    return '<span class="tag ' + cls + '">' + text + '</span>';
  }

  function buildWindow() {
    var win = document.getElementById('win');
    var sb = t('sb');
    var side = '<div class="side-h">ConnectMate</div>';
    sb.forEach(function (name, i) {
      if (i === 6) {
        side += '<div class="side-sep"></div>';
      }
      side += '<div class="side-i" data-sec="' + i + '">' + svg(ICONS[i]) + '<span>' + name + '</span></div>';
    });

    // 中栏：我的 App / 构建版本 / 签名资产
    var apps = '<div class="ph"><h3>' + t('wApps') + '</h3><span class="wbtn">' + t('wRefresh') + '</span><span class="wbtn pri">' + t('wCreate') + '</span></div>' +
      '<div class="wfield">' + svg('<circle cx="11" cy="11" r="6"/><path d="M20 20l-4.5-4.5"/>') + t('wSearch') + '</div>';
    APPS.forEach(function (a, i) {
      apps += '<div class="row' + (i === 0 ? ' sel' : '') + '">' + ic(a) + '<span class="t"><b>' + a[0] + '</b><small>' + a[1] + '</small></span>' + tag('', a[2] === 'IOS' ? 'iOS' : 'macOS') + '</div>';
    });

    var builds = [
      ['1.5.0', '121', 'run', t('stProc'), '10-29 21:12', false],
      ['1.4.0', '118', 'ok', t('stValid'), '10-21 18:40', false],
      ['1.4.0', '117', 'ok', t('stValid'), '10-20 11:05', true],
      ['1.3.2', '112', 'ok', t('stValid'), '09-30 16:22', true],
      ['1.3.1', '109', 'off', t('stExp'), '09-12 09:48', false],
      ['1.3.0', '104', 'bad', t('stInvalid'), '08-27 20:31', false]
    ];
    var bl = '<div class="ph"><h3>' + t('wBuilds') + '</h3><span class="wbtn">' + t('wAddVer') + '</span><span class="wbtn pri">' + t('wExpire') + '</span></div>' +
      '<div class="wfield">' + ic(APPS[0]).replace('class="ic"', 'class="ic" style="width:16px;height:16px;border-radius:4px;font-size:9px;display:grid;place-items:center;color:#fff;background:linear-gradient(135deg,#1c6cdf,#6a2bbd)"') + 'Aurora Notes ▾</div>' +
      '<div class="thead"><span style="width:15px"></span><span style="flex:1">' + t('wVer') + '</span><span style="width:90px">' + t('wStatus') + '</span><span style="width:74px">' + t('wUploaded') + '</span></div>';
    builds.forEach(function (b, i) {
      bl += '<div class="row' + (i === 2 ? ' sel' : '') + '"><span class="chk' + (b[5] ? ' on' : '') + '"></span><span class="t"><b>' + b[0] + ' <span style="font-weight:400;color:var(--w-ink-2)">(' + b[1] + ')</span></b></span><span style="width:90px">' + tag(b[2], b[3]) + '</span><span style="width:74px;font-size:11.5px;color:var(--w-ink-2)">' + b[4] + '</span></div>';
    });

    var profiles = [
      ['Aurora Notes App Store', 'IOS_APP_STORE', 'ok', 'ACTIVE'],
      ['Aurora Notes Development', 'IOS_APP_DEVELOPMENT', 'ok', 'ACTIVE'],
      ['Pixel Lab Ad Hoc', 'IOS_APP_ADHOC', 'ok', 'ACTIVE'],
      ['Tide Timer Direct', 'MAC_APP_DIRECT', 'ok', 'ACTIVE'],
      ['Fieldbook App Store', 'IOS_APP_STORE', 'bad', 'INVALID']
    ];
    var segs = t('wSegs');
    var sl = '<div class="ph"><h3>' + t('wSigning') + '</h3><span class="wbtn">' + t('wRefresh') + '</span><span class="wbtn pri">+</span></div><div class="segc">' +
      segs.map(function (s, i) {
        return '<span' + (i === 3 ? ' class="on"' : '') + '>' + s + '</span>';
      }).join('') + '</div>';
    profiles.forEach(function (p, i) {
      sl += '<div class="row' + (i === 0 ? ' sel' : '') + '"><span class="ic" style="background:linear-gradient(135deg,#2c3a7a,#5b34c9)">' + svg('<path d="M7 3h7l4 4v14H7z"/><path d="M14 3v4h4M10 13h5M10 17h5"/>').replace('<svg', '<svg style="width:16px;height:16px"') + '</span><span class="t"><b>' + p[0] + '</b><small>' + p[1] + '</small></span>' + tag(p[2], p[3]) + '</div>';
    });

    // 右栏详情
    var a = APPS[0];
    var dApps = '<div class="dh">' + ic(a).replace('class="ic"', 'class="ic"') + '<div><b>' + a[0] + '</b><small>' + a[1] + '</small></div></div><dl class="kv">' +
      '<dt>Bundle ID</dt><dd>' + a[1] + '</dd><dt>SKU</dt><dd>AURORA2026</dd><dt>App ID</dt><dd>6740000001</dd>' +
      '<dt>' + t('wPlatform') + '</dt><dd>IOS</dd><dt>' + t('wPrimary') + '</dt><dd>zh-Hans</dd><dt>' + t('wCached') + '</dt><dd>' + t('wCachedV') + '</dd></dl>';
    var dBuilds = '<div class="dh"><span class="ic" style="background:linear-gradient(135deg,#1c6cdf,#6a2bbd)">' + svg(ICONS[1]).replace('<svg', '<svg style="width:28px;height:28px"') + '</span><div><b>1.4.0 (117)</b><small>Aurora Notes</small></div></div><dl class="kv">' +
      '<dt>Build ID</dt><dd>8c1e5a2f-0d7b-4c11-9a3e-…</dd><dt>' + t('wVer') + '</dt><dd>1.4.0</dd><dt>' + t('wBuildNo') + '</dt><dd>117</dd>' +
      '<dt>' + t('wStatus') + '</dt><dd>VALID</dd><dt>' + t('wPlatform') + '</dt><dd>IOS</dd><dt>' + t('wUploaded') + '</dt><dd>2026-10-20 11:05</dd><dt>' + t('wExpired') + '</dt><dd>' + t('wNo') + '</dd></dl>';
    var dSign = '<div class="dh"><span class="ic" style="background:linear-gradient(135deg,#2c3a7a,#5b34c9)">' + svg('<path d="M7 3h7l4 4v14H7z"/><path d="M14 3v4h4M10 13h5M10 17h5"/>').replace('<svg', '<svg style="width:28px;height:28px"') + '</span><div><b>Aurora Notes App Store</b><small>IOS_APP_STORE</small></div></div><dl class="kv">' +
      '<dt>ID</dt><dd>4Q7NZ2L8XK</dd><dt>' + t('wName') + '</dt><dd>Aurora Notes App Store</dd><dt>' + t('wType') + '</dt><dd>IOS_APP_STORE</dd>' +
      '<dt>' + t('wPState') + '</dt><dd>ACTIVE</dd><dt>Bundle ID</dt><dd>com.example.aurora</dd><dt>' + t('wExpire2') + '</dt><dd>2027-10-12</dd></dl>' +
      '<div class="dact"><span class="wbtn pri">' + t('wDownload') + '</span><span class="wbtn">' + t('wDelete') + '</span></div>';

    // API Key 表单
    var sheet = '<h4>' + t('kTitle') + ' <span class="tag ok" style="margin-left:6px">' + t('kActive') + '</span></h4>' +
      '<div class="drop">' + svg('<path d="M7 3h7l4 4v14H7z"/><path d="M14 3v4h4"/><circle cx="11" cy="14" r="2"/><path d="M12.4 15.4L15 18"/>') + '<div><b>AuthKey_ABCD1234EF.p8</b><small>' + t('kDrop') + '</small></div></div>' +
      '<div class="fl"><label>' + t('kName') + '</label><span class="in">Studio</span><label>Issuer ID</label><span class="in">69a6de7f-xxxx-47e3-xxxx-5b8c7c11a4d1</span><label>Key ID</label><span class="in">ABCD1234EF</span></div>' +
      '<p class="okline" id="okline">' + svg('<circle cx="12" cy="12" r="9"/><path d="M8 12l3 3 5-6"/>').replace('<svg', '<svg style="width:14px;height:14px"') + t('kOk') + '</p>' +
      '<div class="acts"><span class="wbtn">' + t('kValidate') + '</span><span class="wbtn pri">' + t('kSave') + '</span></div>';

    win.innerHTML =
      '<div class="tb"><div class="lights"><i></i><i></i><i></i></div><div class="tb-title">ConnectMate</div>' +
      '<div class="tb-task"><span id="taskText">' + t('taskIdle') + '</span><span class="bar"><b id="taskBar"></b></span></div></div>' +
      '<div class="wbody">' +
      '<div class="pane side">' + side + '</div>' +
      '<div class="pane list"><div class="views">' +
      '<div class="v" data-v="apps">' + apps + '</div><div class="v" data-v="builds">' + bl + '</div><div class="v" data-v="signing">' + sl + '</div>' +
      '</div></div>' +
      '<div class="pane detail"><div class="views">' +
      '<div class="v" data-v="apps">' + dApps + '</div><div class="v" data-v="builds">' + dBuilds + '</div><div class="v" data-v="signing">' + dSign + '</div>' +
      '</div></div>' +
      '</div><div class="sheet">' + sheet + '</div>';
  }

  // ---------- 滚动叙事 ----------
  // 每一段：侧边栏选中项、中右栏视图、焦点区域、对应的 asc 命令
  var STEPS = [
    { sec: 0, view: 'apps', focus: 'sheet', cmd: 'asc auth login --name Studio --key-id ABCD1234EF --issuer-id 69a6de7f-… --private-key AuthKey_ABCD1234EF.p8 --network', out: 'o0' },
    { sec: 0, view: 'apps', focus: 'list', cmd: 'asc apps list', out: 'o1' },
    { sec: 1, view: 'builds', focus: 'list', cmd: 'asc builds expire --build 8c1e5a2f-… --confirm', out: 'o2', task: true },
    { sec: 5, view: 'signing', focus: 'detail', cmd: 'asc profiles download --id 4Q7NZ2L8XK --output ~/Downloads', out: 'o3' }
  ];
  var current = 0;
  var typingTimer = null;
  var outTimer = null;
  var taskTimer = null;

  function typeCommand(step, instant) {
    var cmdEl = document.getElementById('cmd');
    var outEl = document.getElementById('out');
    clearInterval(typingTimer);
    clearTimeout(outTimer);
    outEl.classList.remove('on');
    outEl.innerHTML = t(step.out);
    var ok = document.getElementById('okline');
    if (ok) {
      ok.classList.remove('on');
    }
    var finish = function () {
      cmdEl.textContent = step.cmd;
      outTimer = setTimeout(function () {
        outEl.classList.add('on');
        if (ok && step.focus === 'sheet') {
          ok.classList.add('on');
        }
      }, instant ? 0 : 260);
    };
    if (instant || reduceMotion.matches) {
      finish();
      return;
    }
    var i = 0;
    cmdEl.textContent = '';
    var per = Math.max(10, Math.min(28, 900 / step.cmd.length));
    typingTimer = setInterval(function () {
      i += 1;
      cmdEl.textContent = step.cmd.slice(0, i);
      if (i >= step.cmd.length) {
        clearInterval(typingTimer);
        finish();
      }
    }, per);
  }

  function setStep(n, instant) {
    current = n;
    var s = STEPS[n];
    var win = document.getElementById('win');
    win.dataset.focus = s.focus;
    win.querySelectorAll('.side-i').forEach(function (el) {
      el.classList.toggle('on', Number(el.dataset.sec) === s.sec);
    });
    win.querySelectorAll('.v').forEach(function (el) {
      el.classList.toggle('on', el.dataset.v === s.view);
    });
    document.querySelectorAll('.cap').forEach(function (el) {
      el.classList.toggle('on', Number(el.dataset.cap) === n);
    });
    document.querySelectorAll('#stepnav button').forEach(function (b) {
      if (Number(b.dataset.go) === n) {
        b.setAttribute('aria-current', 'step');
      } else {
        b.removeAttribute('aria-current');
      }
    });
    // 批量过期一段演示后台任务进度条
    var bar = document.getElementById('taskBar');
    var text = document.getElementById('taskText');
    clearTimeout(taskTimer);
    if (s.task) {
      text.textContent = t('task');
      bar.style.transform = 'scaleX(0)';
      taskTimer = setTimeout(function () {
        bar.style.transform = 'scaleX(1)';
        taskTimer = setTimeout(function () {
          text.textContent = t('taskIdle');
        }, 1100);
      }, instant ? 0 : 700);
    } else {
      text.textContent = t('taskIdle');
      bar.style.transform = 'scaleX(0)';
    }
    typeCommand(s, instant);
  }

  var story = document.getElementById('story');
  root.style.setProperty('--steps', STEPS.length);

  function stepFromScroll() {
    var rect = story.getBoundingClientRect();
    var total = story.offsetHeight - window.innerHeight;
    var p = total > 0 ? Math.min(1, Math.max(0, -rect.top / total)) : 0;
    return Math.min(STEPS.length - 1, Math.floor(p * STEPS.length));
  }

  var ticking = false;
  window.addEventListener('scroll', function () {
    if (ticking) {
      return;
    }
    ticking = true;
    requestAnimationFrame(function () {
      ticking = false;
      var n = stepFromScroll();
      if (n !== current) {
        setStep(n, false);
      }
    });
  }, { passive: true });

  document.getElementById('stepnav').addEventListener('click', function (e) {
    var b = e.target.closest('button');
    if (!b) {
      return;
    }
    var n = Number(b.dataset.go);
    var total = story.offsetHeight - window.innerHeight;
    var top = story.getBoundingClientRect().top + window.scrollY + total * (n + 0.5) / STEPS.length;
    window.scrollTo({ top: top, behavior: reduceMotion.matches ? 'auto' : 'smooth' });
  });

  // 按可用空间缩放窗口示意
  var frame = document.getElementById('frame');
  var stage = frame.parentElement;

  function fit() {
    var wide = window.innerWidth >= 1100;
    var availW = wide ? stage.clientWidth - 380 - 48 : stage.clientWidth;
    var reserve = wide ? 130 : (window.innerWidth <= 600 ? 330 : 360);
    var availH = stage.clientHeight - reserve;
    var s = Math.min(availW / 960, availH / 560, 1.1);
    s = Math.max(0.2, s);
    root.style.setProperty('--s', s.toFixed(4));
  }

  window.addEventListener('resize', fit);

  // ---------- 动画暂停：页面不可见或首屏离开视口 ----------
  var hero = document.querySelector('.hero');
  var heroVisible = true;

  function updatePaused() {
    root.classList.toggle('paused', document.hidden || !heroVisible);
  }

  document.addEventListener('visibilitychange', updatePaused);
  if ('IntersectionObserver' in window) {
    new IntersectionObserver(function (entries) {
      heroVisible = entries[0].isIntersecting;
      updatePaused();
    }).observe(hero);

    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        if (en.isIntersecting) {
          en.target.classList.add('in');
          io.unobserve(en.target);
        }
      });
    }, { rootMargin: '0px 0px -8% 0px' });
    document.querySelectorAll('.reveal').forEach(function (el) {
      io.observe(el);
    });
  } else {
    document.querySelectorAll('.reveal').forEach(function (el) {
      el.classList.add('in');
    });
  }

  // ---------- 下载链接：读取最新 Release，失败时保留 releases/latest ----------
  function applyRelease() {
    document.querySelectorAll('[data-dl]').forEach(function (a) {
      a.href = release.url;
    });
    document.querySelectorAll('[data-ver]').forEach(function (el) {
      el.textContent = release.version;
    });
    var meta = document.querySelector('[data-i18n="metaLine"]');
    if (meta) {
      meta.textContent = fmt(t('metaLine'));
    }
    document.querySelectorAll('[data-size]').forEach(function (el) {
      el.textContent = t('sizeFmt').replace('{s}', release.size);
    });
  }

  if (window.fetch) {
    fetch('https://api.github.com/repos/' + REPO + '/releases/latest', { headers: { Accept: 'application/vnd.github+json' } })
      .then(function (r) {
        if (!r.ok) {
          throw new Error(String(r.status));
        }
        return r.json();
      })
      .then(function (data) {
        var dmgs = (data.assets || []).filter(function (x) {
          return /\.dmg$/i.test(x.name);
        });
        if (!dmgs.length) {
          return;
        }
        var asset = dmgs[0];
        release.url = asset.browser_download_url;
        release.version = String(data.tag_name || '').replace(/^v/i, '') || release.version;
        release.size = (asset.size / 1048576).toFixed(1) + ' MB';
        applyRelease();
      })
      .catch(function () {
        applyRelease();
      });
  }

  // ---------- 初始化 ----------
  applyTheme(root.dataset.pref, false);
  applyLang(lang, false);
  fit();
  // 验收用：?step=n 直接滚动到第 n 段
  var stepParam = new URLSearchParams(location.search).get('step');
  if (stepParam !== null && STEPS[Number(stepParam)]) {
    var total0 = story.offsetHeight - window.innerHeight;
    window.scrollTo(0, story.getBoundingClientRect().top + window.scrollY + total0 * (Number(stepParam) + 0.5) / STEPS.length);
  }
  current = stepFromScroll();
  setStep(current, false);
  requestAnimationFrame(function () {
    requestAnimationFrame(function () {
      root.classList.remove('boot');
    });
  });
})();
