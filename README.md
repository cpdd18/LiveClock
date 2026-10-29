# 灵动时钟 LiveClock（iOS 自签名实时活动时钟）

一款面向 **付费 Apple 开发者账号**、在 **Windows 上开发、云端 Mac 构建签名** 的 iPhone 时钟 App：
主界面全屏时钟（数字/指针、秒级），一键把 `时:分` + 日期星期推送到 **灵动岛与锁屏实时活动**；另提供 **画中画（PiP）悬浮时钟窗**，切到其他 App 后小窗仍在屏幕上显示时间，内置 4 套皮肤。

---

## 1. 功能一览

| 模块 | 能力 |
|---|---|
| 主 App 全屏时钟 | 数字大时钟 `HH:mm:ss`（每秒刷新）；指针表盘（时针/分针/秒针）；日期星期 |
| 灵动岛紧凑态 | 左侧时钟图标 + 右侧 `HH:mm` |
| 灵动岛展开态（长按） | 大号 `HH:mm` + 日期星期 |
| 锁屏横幅 | 大时间 + 日期星期（非灵动岛机型同样可用） |
| 画中画悬浮窗（PiP） | 系统级悬浮小窗，切到其他 App / 桌面仍显示 `时:分` + 日期；每秒一帧；支持拖动位置、切换大小 |
| 皮肤系统 | 暗夜 / 荧光 / 暖阳 / 极简，切换后主界面、实时活动、PiP 窗同步变色 |
| 生命周期 | App 内一键开启 / 关闭实时活动与 PiP；启动前自动清理旧活动避免叠加 |
| 构建方式 | XcodeGen 工程描述 + GitHub Actions 云端 macOS runner 自动签名导出 IPA |

## 2. 必读：苹果系统硬约束（无法绕过）

1. **实时活动不支持秒级跳动。** 活动运行在独立沙盒、不能联网，本地更新被系统节流；所以“秒”只出现在主 App 全屏界面，灵动岛/锁屏只显示 **时:分**。
2. **单次实时活动最长 8 小时。** 到点系统自动从灵动岛移除；锁屏横幅最多再保留 4 小时。重新打开 App 点“开启灵动岛时钟”即可复活。
3. **内容数据 ≤ 4KB**（本项目字段精简，远低于上限）。
4. **最低系统 iOS 17.0**；灵动岛为 iPhone 14 Pro 及以上机型，其余机型以锁屏横幅形式展示。
5. 用户可在「设置 → 灵动时钟 → 实时活动」手动关闭，App 内会检测 `areActivitiesEnabled` 并提示。
6. **画中画窗口不可点击、无按钮**，只展示画面；由 `AVPictureInPictureController` 承载，需在主 App 内启动；`Info.plist` 已声明 `UIBackgroundModes: audio` 以维持后台帧；是否允许手动拉起以真机系统策略为准，不支持时界面会显示提示而非崩溃。

参考：Apple Developer Documentation — [Displaying live data with Live Activities](https://developer.apple.com/documentation/ActivityKit/displaying-live-data-with-live-activities)。

## 3. 工程结构

```
LiveClock/
├── project.yml                    # XcodeGen 工程描述（不提交 .xcodeproj）
├── App/                          # 主 App：全屏时钟 + 皮肤 + 活动管理
│   ├── LiveClockApp.swift
│   ├── Info.plist
│   ├── LiveClock.entitlements
│   ├── Models/{AppPalette, ClockSettings}.swift
│   ├── Manager/{ClockActivityManager, PiPClockManager}.swift
│   └── Views/{ClockContentView, DigitClockView, AnalogClockView, SkinPickerView, PiPClockContainer}.swift
├── Widget/                       # Widget Extension：实时活动四区域视图
│   ├── ClockWidget.swift
│   ├── WidgetPalette.swift
│   ├── Info.plist
│   └── ClockWidget.entitlements
├── Shared/                       # 主 App 与 Extension 共同编译的纯逻辑代码
│   ├── ClockAttributes.swift
│   ├── SkinID.swift
│   └── ClockFormatters.swift
├── Resources/Assets.xcassets/
├── scripts/
│   ├── make_certificate_windows.py   # Windows 生成 CSR / p12 辅助
│   └── exportOptions.template.plist  # 导出签名配置模板
├── .github/workflows/build-ipa.yml    # 云端 Mac 构建签名流水线
└── docs/Windows构建与签名指南.md      # 逐步操作手册
```

技术栈：SwiftUI + ActivityKit + WidgetKit + AVKit（PiP）；手动签名（Manual Code Signing）；无第三方依赖、无推送服务器。

## 4. 占位符替换清单（首次使用必做）

全局搜索并替换以下占位值，全部要与开发者门户注册值**逐字符一致**：

| 占位值 | 出现位置 | 替换为 |
|---|---|---|
| `com.example.liveclock` | `project.yml`（主 target）、`scripts/exportOptions.template.plist` | 主 App Bundle ID / App ID |
| `com.example.liveclock.widget` | `project.yml`（扩展 target）、`scripts/exportOptions.template.plist` | Widget Extension Bundle ID |
| `group.com.example.liveclock` | `App/LiveClock.entitlements`、`Widget/ClockWidget.entitlements`、`App/Models/ClockSettings.swift` | App Group ID |

另需在 GitHub Secrets 配置 `DEVELOPMENT_TEAM`（开发者门户 Membership 页的 10 位 Team ID）。

## 5. 两条落地路线

### 路线 A（推荐主线）：Windows + GitHub Actions 云端构建

前提：付费 Apple Developer 账号（99 美元/年）、GitHub 仓库、Windows 装 Git 与 GitHub CLI。

完整逐步操作见 **[docs/Windows构建与签名指南.md](docs/Windows构建与签名指南.md)**，摘要：

1. 开发者门户注册 2 个 App ID + 1 个 App Group 并互相关联；注册本机设备 UDID；生成 Apple Development 证书与 2 份 Development 描述文件。
2. Windows 上用 `scripts/make_certificate_windows.py` 生成 CSR 与 legacy 格式 `dist.p12`。
3. 首次先触发 `Build Signed IPA`：`compile-only` 验证能否编译；`simulator-preview` 自动在模拟器启动并截图，免证书自测 UI（见下方「免签名自测」）。
4. 再在 Settings → Secrets 配置 7 个 Secret（见指南清单），切换 **signed-ipa** 模式触发构建（导出方式默认 `development` 自用调试直装；多设备分发时门户加入设备后选 `ad-hoc`），下载产物 IPA。
5. Windows 用爱思助手 / iMazing 连接 iPhone 直接安装已签名 IPA。

### 路线 B（兜底）：临时借一台 Mac 本地跑通

若首次调试不想折腾 CI：

1. Mac 上 `brew install xcodegen`，克隆本仓库。
2. 把 `project.yml` 中 `CODE_SIGN_STYLE: Manual` 改为 `Automatic`，并删除两个 target 下的 `CODE_SIGN_IDENTITY`、`PROVISIONING_PROFILE_SPECIFIER` 行。
3. 执行 `xcodegen generate`，用 Xcode 打开 `LiveClock.xcodeproj`，Signing 页选自己团队，连接 iPhone 直接 Run。
4. 跑通后再回到路线 A 把签名材料迁到 CI。

### 免签名自测（模拟器截图，无需开发者账号）

不想先配证书时，触发 **`simulator-preview`** 模式：云端 Mac 自动编译 Debug 版 → 启动 iPhone 模拟器 → 安装并启动 App → 把界面截图作为 Artifact 上传，下载即可查看主界面布局、数字时钟与皮肤配色。

模拟器限制（务必知悉）：

- **画中画（PiP）模拟器不支持**，界面会显示“不支持画中画”提示，属正常，必须真机验证；
- 灵动岛为模拟渲染，动画、手感与真机有差异；
- 截图是自动启动后的静态画面，不能手动点按切换皮肤；皮肤切换效果以代码逻辑为准，真机再验。

> 真机上不存在“零签名运行”：最低成本是免费 Apple ID 用 Sideloadly 侧载（7 天有效、到期重签），但仍需先有编译产物；正式长期使用走付费账号 signed-ipa 最省事。

## 6. 自定义指南

- **新增皮肤**：① `Shared/SkinID.swift` 加枚举 case；② `App/Models/AppPalette.swift` 与 `Widget/WidgetPalette.swift` 各补一个配色分支；`SkinPickerView` 遍历 `allCases` 自动出现新选项。
- **修改时间格式**：统一改 `Shared/ClockFormatters.swift`。
- **给实时活动加快捷按钮**（如一键停止）：iOS 17 可用 `Button(intent:)` + App Intent，属于进阶改动，需在 Extension 中新增 AppIntent 类型。
- **调整 PiP 画面**：`App/Manager/PiPClockManager.swift` 中帧尺寸 `320×180`、字体大小、配色分支 `palette(for:)`；帧节拍 `withTimeInterval: 1.0`。
- **图标**：在 `Resources/Assets.xcassets` 内补 `AppIcon.appiconset`（当前未内置图标，不影响自签安装，仅影响桌面观感）。

## 7. 常见报错排查

| 报错 / 现象 | 原因 | 处理 |
|---|---|---|
| `No signing certificate "iOS Development" found` | p12 未导入或缺分区列表授权 | 确认 workflow 中 `set-key-partition-list` 执行；p12 用 `-legacy` 方式导出 |
| `Provisioning profile ... doesn't include the device` | 设备 UDID 未进描述文件 | 门户 Devices 添加 UDID，重新生成 profile 并更新 Secret |
| `application-groups` entitlement 不匹配 | App Group 未关联到两个 App ID | 门户 App ID → Configure 勾选同一 Group；两端 entitlements 一致 |
| 灵动岛不出现、锁屏无横幅 | 设置中关闭实时活动，或机型无灵动岛 | 设置 → 灵动时钟 → 实时活动 打开；非 Pro 机型看锁屏横幅 |
| 8 小时后消失 | 系统限制 | 重新点“开启灵动岛时钟” |
| 活动上看不到秒 | 设计如此（系统不支持秒级刷新） | 秒表在主 App 界面查看 |
| PiP 点开启无小窗 / 按钮不可用 | 设备系统不支持，或 `UIBackgroundModes` 缺失 | 确认 iOS 17+、`Info.plist` 含 `audio` 后台模式；界面提示“不支持”即属系统限制 |
| PiP 窗内时间不随秒跳动 | 设计节拍为每秒一帧；后台可能被系统节流 | 精确秒表看主界面；小窗用于瞥一眼时:分 |
| Extension 编译报 `NSExtensionPointIdentifier` 缺失 | Widget `Info.plist` 键被删 | 保留 `com.apple.widgetkit-extension` |
| archive 报 Info.plist 生成冲突 | 手写 plist 时开启了自动生成 | 不要在 `project.yml` 设置 `GENERATE_INFOPLIST_FILE: YES` |

## 8. 许可与免责

个人自用自签项目。上架 App Store 需额外满足审核要求（图标、隐私清单、Guideline 4.2 等），本仓库未按上架标准配置。
