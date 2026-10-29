import SwiftUI

/// 数字时钟（秒级刷新只在主 App 界面成立）。
struct DigitClockView: View {
    let now: Date
    let theme: ClockTheme
    let showSeconds: Bool

    private var timeText: String {
        showSeconds
            ? ClockFormatters.fullTime.string(from: now)
            : ClockFormatters.shortTime.string(from: now)
    }

    var body: some View {
        Text(timeText)
            .font(.system(size: showSeconds ? 62 : 84, weight: .bold, design: .monospaced))
            .monospacedDigit()
            .foregroundStyle(theme.primary)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
    }
}
