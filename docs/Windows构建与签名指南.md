# Windows 无 Mac 构建签名安装指南（付费开发者账号）

本指南把整条链路拆成 5 步：**门户配置 → Windows 出证书材料 → 配 GitHub Secrets → 云端构建 → Windows 安装**。
全程不需要 Mac；云端 macOS runner 负责编译与签名。

> 链路总览：Windows 写代码 → push 到 GitHub → Actions 云端 Mac 执行 `xcodegen generate` + `xcodebuild archive` + `exportArchive` → 产出签名 IPA → 下载到 Windows → 爱思/iMazing 装到 iPhone。

---

## 第 0 步：准备清单

- [ ] 付费 Apple Developer Program 账号（99 美元/年），能登录 [developer.apple.com/account](https://developer.apple.com/account)
- [ ] 一台 Windows 电脑，已装：Git、GitHub CLI（`gh`）、Python 3（可选，仅用于辅助脚本）、OpenSSL（Git for Windows 自带，命令行输入 `openssl version` 能出版本即可）
- [ ] GitHub 仓库（公开仓库 macOS 构建分钟数免费；私有仓库按分钟计费，单次构建约 4–8 分钟）
- [ ] 自己的 iPhone 一台，数据线一根

---

## 第 1 步：开发者门户配置（约 20 分钟，只做一次）

登录 [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/)。

### 1.1 注册两个 App ID

Identifiers → 左上角 `+`：

1. **主 App ID**：Bundle ID 选 Explicit，填例如 `com.你的名字.liveclock`；Capabilities 勾选 **App Groups**。
2. **Widget App ID**：`com.你的名字.liveclock.widget`；同样勾选 **App Groups**。
   > 不需要勾 Push Notifications：本项目不接 APNs，实时活动全部本地更新。

### 1.2 注册并关联 App Group

1. Identifiers 顶部切到 **App Groups** → `+`，创建 `group.com.你的名字.liveclock`。
2. 回到两个 App ID 的编辑页 → App Groups → Configure → 勾选上面这个 Group 并保存。
3. 同步把 `project.yml`、两个 `entitlements`、`ClockSettings.swift` 中的 `group.com.example.liveclock` 替换为该值。

### 1.3 注册本机设备 UDID

1. iPhone 用数据线连 Windows，打开爱思助手 → 设备信息页复制 **UDID**（40 位十六进制）。
2. 门户 Devices → `+`，粘贴 UDID，命名如 `My iPhone`。
   > Development 描述文件必须包含设备，否则导出的 IPA 装不上。

### 1.4 生成开发证书

1. 按第 2 步在 Windows 生成 `csr.csr`。
2. Certificates → `+` → 选 **Apple Development** → 粘贴 CSR 内容 → 下载得到 `.cer` 文件。

### 1.5 创建两份 Development 描述文件

Profiles → `+` → 选 **iOS App Development**：

| 描述文件 | App ID | 证书 | 设备 |
|---|---|---|---|
| `LiveClock-Dev-App` | 主 App ID | 第 1.4 步证书 | 勾选本机 iPhone |
| `LiveClock-Dev-Widget` | Widget App ID | 同一证书 | 勾选本机 iPhone |

分别下载得到 `LiveClock-Dev-App.mobileprovision`、`LiveClock-Dev-Widget.mobileprovision`。
> 描述文件名称要记准，后面 GitHub Secret 里的 `APP_PROFILE_NAME` / `WIDGET_PROFILE_NAME` 必须与此**完全一致**。

---

## 第 2 步：Windows 生成证书材料

在仓库 `scripts` 目录打开 Git Bash：

```bash
# 2.1 生成私钥 + CSR
openssl genrsa -out private_key.pem 2048
openssl req -new -key private_key.pem -out csr.csr -subj "/CN=LiveClock Development/O=Self/C=CN"
```

把 `csr.csr` 全文粘贴到门户第 1.4 步，下载 `ios_development.cer` 后：

```bash
# 2.2 DER 证书转 PEM
openssl x509 -inform DER -in ios_development.cer -out cert.pem

# 2.3 打包为 legacy 格式 p12（macOS security import 才能识别；-legacy 不可省略）
openssl pkcs12 -export -legacy -inkey private_key.pem -in cert.pem \
  -name "LiveClock Dev" -out dist.p12 -passout pass:设置一个p12密码
```

也可以先运行 `python make_certificate_windows.py steps` 查看命令模板。

> 安全红线：`private_key.pem`、`dist.p12`、`.mobileprovision` 永远不要提交到 Git（`.gitignore` 已默认排除）。

---

## 第 3 步：配置 GitHub Secrets

仓库页面 → Settings → Secrets and variables → Actions → New repository secret，共 **7 项**：

| Secret 名称 | 值来源 |
|---|---|
| `DEVELOPMENT_TEAM` | 门户 Membership 页的 10 位 Team ID（如 `ABC123DEFG`） |
| `P12_BASE64` | `dist.p12` 的单行 base64：`python make_certificate_windows.py b64 dist.p12`，复制输出 |
| `P12_PASSWORD` | 第 2.3 步设置的 p12 密码 |
| `APP_PROFILE_NAME` | `LiveClock-Dev-App`（与门户 Profile 名逐字符一致） |
| `APP_PROFILE_BASE64` | `python make_certificate_windows.py b64 LiveClock-Dev-App.mobileprovision` |
| `WIDGET_PROFILE_NAME` | `LiveClock-Dev-Widget` |
| `WIDGET_PROFILE_BASE64` | `python make_certificate_windows.py b64 LiveClock-Dev-Widget.mobileprovision` |

同时确认 `project.yml` 里三个 Bundle ID / Group 已替换为门户真实值。

---

## 第 4 步：触发云端构建并下载 IPA

先提交并推送代码：

```bash
git add .
git commit -m "init live clock"
git push origin main
```

### 4.1 先跑 compile-only（无需证书，验证编译）

```bash
gh workflow run build-ipa.yml -f mode=compile-only
gh run watch
```

绿色通过说明工程可编译；失败则看日志报错对照 README 第 7 节排查表。

### 4.2 再跑 signed-ipa（产出签名 IPA）

Secrets 配好后：

```bash
gh workflow run build-ipa.yml -f mode=signed-ipa -f build_number=1
gh run watch
```

构建成功后：

1. 仓库 → Actions → 最近一次运行 → 底部 **Artifacts** 下载 `LiveClock-development-ipa`（zip 内即 IPA）。
2. 解压得到 `LiveClock.ipa`。

> signed-ipa 失败最常见原因：Profile 名与 Secret 不一致、设备未注册、p12 非 legacy 格式；compile-only 失败则通常是代码或工程配置问题。

---

## 第 5 步：Windows 安装到 iPhone

任选其一（IPA 已带 Development 签名，无需再重签）：

### 方式一：爱思助手（推荐，免费中文界面）

1. iPhone 连电脑，信任设备；打开爱思助手 → 「应用游戏」→「导入安装」。
2. 选择 `LiveClock.ipa`，等待安装完成；桌面出现“灵动时钟”图标。
3. 首次打开若提示“未受信任的开发者”：设置 → 通用 → VPN与设备管理 → 点开发者证书 → 信任。

### 方式二：iMazing

设备 → 应用管理 → 拖入 IPA 安装（免费版对安装数量有限制，自用一般够用）。

### 方式三：Sideloadly（备选）

若前两者不可用，可用 Sideloadly；注意它默认会用 Apple ID 重签，与本项目 Development 签名路线不同，仅作兜底。

### 安装后验证清单

- [ ] 打开 App，全屏时钟每秒走秒，日期星期正确
- [ ] 点「开启灵动岛时钟」，灵动岛出现图标 + `HH:mm`；长按展开看大时间
- [ ] 锁屏状态下看到时钟横幅
- [ ] 切换 4 套皮肤，灵动岛颜色同步变化
- [ ] 点「关闭灵动岛时钟」，活动从灵动岛移除
- [ ] 点「开启画中画悬浮窗」，出现可拖动的时钟小窗；切回桌面 / 其他 App 小窗仍在
- [ ] 切换皮肤后 PiP 小窗配色同步变化；点「关闭画中画悬浮窗」小窗消失

### 画中画（PiP）使用说明

1. PiP 由 `AVPictureInPictureController` 承载，帧画面在 `App/Manager/PiPClockManager.swift` 内每秒绘制一帧（320×180）。
2. `Info.plist` 已声明 `UIBackgroundModes = audio`，用于后台维持帧渲染；本项目不播放声音。
3. 小窗不可点击、无按钮；可拖动位置、双指缩放大小；关闭需回到 App 点「关闭画中画悬浮窗」。
4. 若界面提示“当前设备 / 系统不支持画中画”，说明系统策略限制（极少数机型 / 系统版本），实时活动时钟仍可正常使用。

---

## 日常迭代流程

改完代码后重复：`git push` → `gh workflow run build-ipa.yml -f build_number=递增整数` → 下载 IPA → 覆盖安装。
Development 签名有效期跟随证书与描述文件（通常 1 年），到期前在门户续期并更新对应 Secret 即可。

## 常见问题速查

- **装完点开闪退**：多半是签名 entitlement 与 profile 不匹配（App Group 未关联 / Bundle ID 不一致），回第 1 步核对。
- **灵动岛不出现但锁屏有横幅**：机型无灵动岛（iPhone 14 Pro 以下），属正常；或设置里关闭了实时活动。
- **构建卡在 codesign 弹窗超时**：workflow 中 `set-key-partition-list` 未生效，确认 p12 为 `-legacy` 导出。
- **PiP 小窗拉不起来**：先确认设备支持（`isPictureInPictureSupported()`）；检查 `Info.plist` 的 `UIBackgroundModes` 含 `audio`；真机上重启 App 重试；模拟器不支持 PiP，必须真机验证。
- **想分发给多台设备**：把每台设备 UDID 加入门户并重新生成 Development（或改用 Ad Hoc）描述文件，更新 Secret 后重新构建。
