import SwiftUI

/// Widget Extension 精简配色（只含活动视图需要的颜色）。
struct WidgetTheme {
    let background: Color
    let primary: Color
    let accent: Color
}

extension SkinID {
    var widgetTheme: WidgetTheme {
        switch self {
        case .midnight:
            return WidgetTheme(
                background: Color(red: 0.04, green: 0.05, blue: 0.10),
                primary: .white,
                accent: Color(red: 0.35, green: 0.85, blue: 1.00))
        case .neon:
            return WidgetTheme(
                background: .black,
                primary: Color(red: 0.25, green: 1.00, blue: 0.45),
                accent: Color(red: 1.00, green: 0.90, blue: 0.30))
        case .warm:
            return WidgetTheme(
                background: Color(red: 0.17, green: 0.10, blue: 0.06),
                primary: Color(red: 1.00, green: 0.82, blue: 0.55),
                accent: Color(red: 1.00, green: 0.55, blue: 0.25))
        case .minimal:
            return WidgetTheme(
                background: Color(.systemBackground),
                primary: Color(.label),
                accent: Color(.secondaryLabel))
        }
    }
}
