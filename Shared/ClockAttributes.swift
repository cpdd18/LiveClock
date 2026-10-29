import ActivityKit

/// 实时活动（灵动岛 / 锁屏横幅）的数据模型。
///
/// 说明：
/// - `ActivityAttributes` 本体只承载“静态数据”，本 App 没有静态字段，因此保持空实现。
/// - `ContentState` 承载“动态数据”，必须 Codable & Hashable，且全量静态 + 动态数据
///   合计不得超过 4KB（苹果硬性限制）。本结构字段精简，远低于上限。
/// - 秒数不放入 ContentState：实时活动被系统节流，无法秒级刷新；秒表只出现在主 App 全屏界面。
public struct ClockAttributes: ActivityAttributes {

    public struct ContentState: Codable, Hashable {
        /// “HH:mm”，灵动岛紧凑区与锁屏横幅使用。
        public var timeText: String
        /// “HH:mm:ss”，仅展开视图可选展示；活动后台更新频率低，仅供参考。
        public var secondText: String
        /// “10月29日”
        public var dateText: String
        /// “星期四”
        public var weekdayText: String
        /// 皮肤标识原始值（SkinID.rawValue）。
        public var skinID: String

        public init(timeText: String,
                    secondText: String,
                    dateText: String,
                    weekdayText: String,
                    skinID: String) {
            self.timeText = timeText
            self.secondText = secondText
            self.dateText = dateText
            self.weekdayText = weekdayText
            self.skinID = skinID
        }
    }

    public init() {}
}
