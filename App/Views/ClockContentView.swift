import SwiftUI

struct ClockContentView: View {
    @EnvironmentObject private var settings: ClockSettings
    @EnvironmentObject private var manager: ClockActivityManager
    @EnvironmentObject private var pipManager: PiPClockManager

    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var dateLine: String { ClockFormatters.dateLine.string(from: now) }
    private var weekday: String { ClockFormatters.weekday.string(from: now) }

    var body: some View {
        let theme = settings.skin.theme

        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 26) {
                Text("\(dateLine) · \(weekday)")
                    .font(.subheadline)
                    .foregroundStyle(theme.accent)

                if settings.useAnalog {
                    AnalogClockView(now: now, theme: theme)
                } else {
                    DigitClockView(now: now, theme: theme, showSeconds: settings.showSeconds)
                }

                SkinPickerView(onSelect: selectSkin)

                toggleButton(theme: theme)

                pipSection(theme: theme)

                if let error = manager.lastError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Text("说明：灵动岛 / 锁屏横幅只显示“时:分”，秒表请查看本界面；实时活动最长 8 小时。\n画中画小窗为秒级时:分，窗口不可点击，拖动可调整位置。")
                    .font(.caption2)
                    .foregroundStyle(theme.accent.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .onReceive(timer) { now = $0 }
        .onAppear {
            manager.refreshState()
            pipManager.configure(skin: settings.skin)
        }
        .preferredColorScheme(.dark)
    }

    private func selectSkin(_ skin: SkinID) {
        settings.skin = skin
        settings.useAnalog = skin.theme.useAnalog
        pipManager.configure(skin: skin)
        Task { await manager.update(skin: skin) }
    }

    @ViewBuilder
    private func pipSection(theme: ClockTheme) -> some View {
        if pipManager.pipPossible {
            PiPClockContainer(manager: pipManager)
                .frame(width: 220, height: 124)

            Button {
                if pipManager.pipActive {
                    pipManager.stop()
                } else {
                    pipManager.configure(skin: settings.skin)
                    pipManager.start()
                }
            } label: {
                Text(pipManager.pipActive ? "关闭画中画悬浮窗" : "开启画中画悬浮窗")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(pipManager.pipActive ? theme.accent.opacity(0.18) : theme.accent.opacity(0.85))
                    .foregroundStyle(pipManager.pipActive ? theme.accent : Color.black)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 8)
        } else {
            Text("当前设备 / 系统不支持画中画，可使用上方实时活动时钟。")
                .font(.caption2)
                .foregroundStyle(theme.accent.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    private func toggleButton(theme: ClockTheme) -> some View {
        Button {
            Task {
                if manager.running {
                    await manager.stop()
                } else {
                    await manager.start(skin: settings.skin)
                }
            }
        } label: {
            Text(manager.running ? "关闭灵动岛时钟" : "开启灵动岛时钟")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(manager.running ? theme.accent.opacity(0.18) : theme.accent)
                .foregroundStyle(manager.running ? theme.accent : Color.black)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 8)
    }
}
