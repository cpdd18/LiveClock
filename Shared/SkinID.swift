import Foundation

/// 皮肤标识。主 App 与 Widget Extension 共同编译本文件，
/// 因此两端使用完全一致的枚举与原始值（字符串），便于通过 ContentState 传递。
public enum SkinID: String, Codable, CaseIterable, Identifiable {
    case midnight   // 暗夜
    case neon        // 荧光
    case warm       // 暖阳
    case minimal    // 极简

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .midnight: return "暗夜"
        case .neon:     return "荧光"
        case .warm:     return "暖阳"
        case .minimal:  return "极简"
        }
    }

    /// 解析失败时的兜底值。
    public static func safe(_ raw: String?) -> SkinID {
        guard let raw, let value = SkinID(rawValue: raw) else { return .midnight }
        return value
    }
}
