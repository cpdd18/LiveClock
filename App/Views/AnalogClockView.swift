import SwiftUI

/// 指针表盘。秒针随每秒（实际随定时器节拍）刷新，平滑度由主界面 Timer 节拍决定。
struct AnalogClockView: View {
    let now: Date
    let theme: ClockTheme

    private var seconds: CGFloat {
        let s = Calendar.current.component(.second, from: now)
        let nano = Calendar.current.component(.nanosecond, from: now)
        return CGFloat(s) + CGFloat(nano) / 1_000_000_000
    }

    private var minutes: CGFloat {
        CGFloat(Calendar.current.component(.minute, from: now)) + seconds / 60
    }

    private var hours: CGFloat {
        let h = Calendar.current.component(.hour, from: now) % 12
        return CGFloat(h) + minutes / 60
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(theme.accent.opacity(0.25), lineWidth: 6)
            tickMarks
            hourHand
            minuteHand
            secondHand
            centerDot
        }
        .frame(width: 260, height: 260)
    }

    private var tickMarks: some View {
        ZStack {
            ForEach(0..<60, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(i % 5 == 0 ? theme.accent : theme.accent.opacity(0.35))
                    .frame(width: i % 5 == 0 ? 2.5 : 1,
                           height: i % 5 == 0 ? 12 : 6)
                    .offset(y: -118)
                    .rotationEffect(.degrees(Double(i) * 6))
            }
        }
    }

    private var hourHand: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(theme.primary)
            .frame(width: 5, height: 72)
            .offset(y: -36)
            .rotationEffect(.degrees(Double(hours) * 30))
    }

    private var minuteHand: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(theme.primary)
            .frame(width: 4, height: 96)
            .offset(y: -48)
            .rotationEffect(.degrees(Double(minutes) * 6))
    }

    private var secondHand: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(theme.accent)
            .frame(width: 1.5, height: 108)
            .offset(y: -48)
            .rotationEffect(.degrees(Double(seconds) * 6))
    }

    private var centerDot: some View {
        Circle()
            .fill(theme.accent)
            .frame(width: 8, height: 8)
    }
}
