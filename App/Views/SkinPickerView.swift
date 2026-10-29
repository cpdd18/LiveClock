import SwiftUI

/// 皮肤横向选择器。选中后回调由父视图同步到实时活动。
struct SkinPickerView: View {
    @EnvironmentObject private var settings: ClockSettings
    let onSelect: (SkinID) -> Void

    var body: some View {
        HStack(spacing: 18) {
            ForEach(SkinID.allCases) { skin in
                Button {
                    onSelect(skin)
                } label: {
                    VStack(spacing: 5) {
                        Circle()
                            .fill(skin.theme.primary)
                            .frame(width: 26, height: 26)
                            .overlay(Circle().stroke(skin.theme.accent, lineWidth: 1.5))
                        Text(skin.title)
                            .font(.caption2)
                            .foregroundStyle(skin.theme.primary)
                    }
                }
                .buttonStyle(.plain)
                .opacity(settings.skin == skin ? 1.0 : 0.4)
            }
        }
        .padding(.vertical, 8)
    }
}
