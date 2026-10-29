import ActivityKit
import SwiftUI

/// 实时活动组件：
/// - 锁屏横幅（含不支持灵动岛的机型，以横幅形式出现）
/// - 灵动岛紧凑态 compactLeading / compactTrailing
/// - 灵动岛最小态 minimal（多活动并存时）
/// - 灵动岛展开态 expanded（长按展开，center + bottom 区域）
struct ClockWidget: Widget {
    let kind: String = "ClockWidget"

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ClockAttributes.self) { context in
            LockScreenClockView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    ExpandedCenterView(state: context.state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(state: context.state)
                }
            } compactLeading: {
                Image(systemName: "clock.fill")
                    .foregroundStyle(SkinID.safe(context.state.skinID).widgetTheme.accent)
            } compactTrailing: {
                Text(context.state.timeText)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.white)
            } minimal: {
                Image(systemName: "clock")
            }
        }
    }
}

/// 锁屏横幅视图。
struct LockScreenClockView: View {
    let state: ClockAttributes.ContentState
    private var theme: WidgetTheme { SkinID.safe(state.skinID).widgetTheme }

    var body: some View {
        VStack(spacing: 8) {
            Text(state.timeText)
                .font(.system(size: 34, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(theme.primary)
            Text("\(state.dateText) · \(state.weekdayText)")
                .font(.subheadline)
                .foregroundStyle(theme.accent)
        }
        .padding()
        .activityBackgroundTint(theme.background)
    }
}

/// 展开态中心：大号时:分。
struct ExpandedCenterView: View {
    let state: ClockAttributes.ContentState

    var body: some View {
        Text(state.timeText)
            .font(.system(size: 34, weight: .bold, design: .monospaced))
            .monospacedDigit()
            .foregroundStyle(SkinID.safe(state.skinID).widgetTheme.primary)
    }
}

/// 展开态底部：日期与星期。
struct ExpandedBottomView: View {
    let state: ClockAttributes.ContentState

    var body: some View {
        Text("\(state.dateText)  \(state.weekdayText)")
            .font(.caption)
            .foregroundStyle(SkinID.safe(state.skinID).widgetTheme.accent)
    }
}

@main
struct ClockWidgetBundle: WidgetBundle {
    var body: some Widget {
        ClockWidget()
    }
}
