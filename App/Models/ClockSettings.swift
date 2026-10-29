import SwiftUI

/// 用户偏好（皮肤、表盘样式、是否显示秒）。持久化在 UserDefaults。
/// 注意：实时活动展示内容由 ContentState 携带皮肤标识，Widget 不直接读取本对象。
@MainActor
final class ClockSettings: ObservableObject {
    static let shared = ClockSettings()

    /// App Group 标识，需与开发者门户注册值、两端 entitlements 完全一致。
    static let appGroup = "group.com.example.liveclock"

    @AppStorage("skinRaw") var skinRaw: String = SkinID.midnight.rawValue
    @AppStorage("useAnalog") var useAnalog: Bool = false
    @AppStorage("showSeconds") var showSeconds: Bool = true

    var skin: SkinID {
        get { SkinID.safe(skinRaw) }
        set { skinRaw = newValue.rawValue }
    }

    private init() {}
}
