import SwiftUI

/// 主 App 使用的完整配色主题（含表盘/数字风格选择）。
/// Widget 端使用精简版 WidgetPalette，两端通过 SkinID.rawValue 对齐。
struct ClockTheme {
    let background: Color
    let primary: Color
    let accent: Color
    /// 是否默认使用指针表盘。
    let useAnalog: Bool
}

extension SkinID {
    var theme: ClockTheme {
        switch self {
        case .midnight:
            return ClockTheme(
                background: Color(red: 0.04, green: 0.05, blue: 0.10),
                primary: .white,
                accent: Color(red: 0.35, green: 0.85, blue: 1.00),
                useAnalog: false)
        case .neon:
            return ClockTheme(
                background: .black,
                primary: Color(red: 0.25, green: 1.00, blue: 0.45),
                accent: Color(red: 1.00, green: 0.90, blue: 0.30),
                useAnalog: true)
        case .warm:
            return ClockTheme(
                background: Color(red: 0.17, green: 0.10, blue: 0.06),
                primary: Color(red: 1.00, green: 0.82, blue: 0.55),
                accent: Color(red: 1.00, green: 0.55, blue: 0.25),
                useAnalog: false)
        case .minimal:
            return ClockTheme(
                background: Color(.systemBackground),
                primary: Color(.label),
                accent: Color(.secondaryLabel),
                useAnalog: true)
        }
    }
}
