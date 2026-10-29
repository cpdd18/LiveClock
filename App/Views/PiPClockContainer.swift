import SwiftUI
import AVFoundation

/// 画中画帧预览容器：在主界面显示与 PiP 小窗相同的渲染帧。
/// `displayLayer` 的生命周期由 PiPClockManager 持有，这里只负责布局 frame。
struct PiPClockContainer: UIViewRepresentable {
    let manager: PiPClockManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        manager.displayLayer.frame = view.bounds
        view.layer.addSublayer(manager.displayLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        manager.displayLayer.frame = uiView.bounds
    }
}
