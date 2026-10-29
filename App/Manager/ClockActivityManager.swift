import ActivityKit
import Foundation

/// 实时活动生命周期管理：启动 / 更新 / 结束。
/// 苹果限制：
/// 1. 实时活动最长活跃 8 小时，到点系统自动从灵动岛移除；锁屏横幅最多再保留 4 小时。
/// 2. 后台更新被系统节流，不支持秒级跳动；秒表只放在主 App 全屏界面。
/// 3. 不接入 APNs，全部使用本地 ActivityKit 更新（无需推送证书与服务器）。
@MainActor
final class ClockActivityManager: ObservableObject {
    static let shared = ClockActivityManager()

    @Published private(set) var current: Activity<ClockAttributes>?
    @Published private(set) var running: Bool = false
    @Published var lastError: String?

    /// 用户是否在系统设置中为本 App 开启了“实时活动”。
    static var liveActivityAllowed: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    private init() {
        refreshState()
    }

    func refreshState() {
        let acts = Activity<ClockAttributes>.activities
        running = !acts.isEmpty
        current = acts.first
    }

    private func makeState(skin: SkinID) -> ClockAttributes.ContentState {
        let now = Date()
        return ClockAttributes.ContentState(
            timeText: ClockFormatters.shortTime.string(from: now),
            secondText: ClockFormatters.fullTime.string(from: now),
            dateText: ClockFormatters.dateLine.string(from: now),
            weekdayText: ClockFormatters.weekday.string(from: now),
            skinID: skin.rawValue)
    }

    /// 启动新的实时活动（启动前先清理同名旧活动，避免叠加）。
    func start(skin: SkinID) async {
        guard Self.liveActivityAllowed else {
            lastError = "系统未允许“灵动时钟”使用实时活动。请前往：设置 > 灵动时钟 > 实时活动，打开开关后重试。"
            return
        }
        await stop(dismissal: .immediate)

        let content = ActivityContent(state: makeState(skin: skin), staleDate: nil)
        do {
            let act = try Activity.request(
                attributes: ClockAttributes(),
                content: content,
                pushType: .none)
            current = act
            running = true
            lastError = nil
        } catch {
            lastError = "启动失败：\(error.localizedDescription)。若设备当前实时活动数量已达上限，请先关闭其他活动后重试。"
        }
    }

    /// 切换皮肤 / 刷新时间时同步到正在运行的实时活动。
    func update(skin: SkinID) async {
        let acts = Activity<ClockAttributes>.activities
        guard !acts.isEmpty else { return }
        let content = ActivityContent(state: makeState(skin: skin), staleDate: nil)
        for act in acts {
            await act.update(content)
        }
    }

    /// 结束实时活动。default：锁屏横幅短暂保留；immediate：立即移除。
    func stop(dismissal: ActivityUIDismissalPolicy = .default) async {
        let acts = Activity<ClockAttributes>.activities
        let finalState = makeState(skin: .midnight)
        for act in acts {
            await act.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: dismissal)
        }
        current = nil
        running = false
    }
}
