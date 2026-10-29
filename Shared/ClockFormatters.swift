import Foundation

/// 复用的日期格式化器。DateFormatter 创建成本较高，统一用静态单例。
public enum ClockFormatters {

    /// HH:mm
    public static let shortTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    /// HH:mm:ss
    public static let fullTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    /// M月d日
    public static let dateLine: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_Hans_CN")
        f.dateFormat = "M月d日"
        return f
    }()

    /// 星期几
    public static let weekday: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_Hans_CN")
        f.dateFormat = "EEEE"
        return f
    }()
}
