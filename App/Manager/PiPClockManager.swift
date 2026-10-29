import AVFoundation
import AVKit
import UIKit
import CoreMedia
import CoreVideo
import CoreGraphics

/// 画中画（Picture in Picture, PiP）悬浮时钟管理器。
///
/// 原理：用 `AVSampleBufferDisplayLayer` 逐帧喂入 Core Graphics 绘制的时钟位图，
/// 再交给 `AVPictureInPictureController` 显示为系统悬浮小窗。
/// 不依赖任何视频文件与网络，纯本地每秒一帧。
///
/// 系统限制（如实告知）：
/// 1. PiP 小窗不可点击、无按钮；只展示画面。
/// 2. 需在主 App 内启动；切到其他 App 后小窗由系统维持，帧率为秒级。
/// 3. Info.plist 需声明 `UIBackgroundModes = audio` 以获得后台持续能力。
/// 4. 是否允许手动拉起 PiP 以真机系统策略为准；不支持时 `pipPossible` 为 false。
@MainActor
final class PiPClockManager: NSObject, ObservableObject {
    static let shared = PiPClockManager()

    @Published private(set) var pipActive = false
    @Published private(set) var pipPossible = false

    /// 渲染层：既是帧数据来源，也是 PiP ContentSource。
    /// 所有 UIKit 访问都发生在主线程（UIViewRepresentable 与按钮动作均为主线程回调）。
    let displayLayer = AVSampleBufferDisplayLayer()
    private var pipController: AVPictureInPictureController?
    private var timer: Timer?
    private var skin: SkinID = .midnight

    private override init() {
        super.init()
        displayLayer.videoGravity = .resizeAspectFill
        pipPossible = AVPictureInPictureController.isPictureInPictureSupported()

        if pipPossible {
            let source = AVPictureInPictureController.ContentSource(
                sampleBufferDisplayLayer: displayLayer,
                playbackDelegate: nil)
            let controller = AVPictureInPictureController(contentSource: source)
            controller.canStartPictureInPictureAutomaticallyFromInline = true
            self.pipController = controller
        }
        activateAudioSession()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: 生命周期
    func start() {
        guard pipPossible, let controller = pipController else { return }
        startFrameLoop()
        if !controller.isPictureInPictureActive {
            controller.startPictureInPicture()
        }
        pipActive = true
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        pipController?.stopPictureInPicture()
        displayLayer.flush()
        pipActive = false
    }

    func configure(skin: SkinID) {
        self.skin = skin
        if pipActive { renderFrame() }
    }

    private func startFrameLoop() {
        timer?.invalidate()
        renderFrame()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.renderFrame() }
        }
    }

    private func activateAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    // MARK: 帧渲染
    private func renderFrame() {
        guard let image = Self.makeClockImage(
            size: CGSize(width: 320, height: 180),
            skin: skin,
            now: Date()),
            let pixelBuffer = Self.makePixelBuffer(from: image) else { return }

        var format: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: nil,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &format)
        guard let formatDescription = format else { return }

        var timing = CMSampleTimingInfo(
            duration: CMTime.invalid,
            presentationTimeStamp: CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 10_000),
            decodeTimeStamp: CMTime.invalid)

        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateForImageBuffer(
            allocator: nil,
            imageBuffer: pixelBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDescription,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer)
        guard let buffer = sampleBuffer else { return }

        if displayLayer.isReadyForMoreMediaData {
            displayLayer.enqueue(buffer)
        }
    }

    // MARK: 位图绘制（纯 UIKit 颜色，避免 Color↔UIColor 桥接差异）
    private struct PiPPalette {
        let bg: UIColor
        let primary: UIColor
        let accent: UIColor
    }

    private static func palette(for skin: SkinID) -> PiPPalette {
        switch skin {
        case .midnight:
            return PiPPalette(bg: UIColor(red: 0.04, green: 0.05, blue: 0.10, alpha: 1),
                              primary: .white,
                              accent: UIColor(red: 0.35, green: 0.85, blue: 1.00, alpha: 1))
        case .neon:
            return PiPPalette(bg: .black,
                              primary: UIColor(red: 0.25, green: 1.00, blue: 0.45, alpha: 1),
                              accent: UIColor(red: 1.00, green: 0.90, blue: 0.30, alpha: 1))
        case .warm:
            return PiPPalette(bg: UIColor(red: 0.17, green: 0.10, blue: 0.06, alpha: 1),
                              primary: UIColor(red: 1.00, green: 0.82, blue: 0.55, alpha: 1),
                              accent: UIColor(red: 1.00, green: 0.55, blue: 0.25, alpha: 1))
        case .minimal:
            return PiPPalette(bg: UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1),
                              primary: .black,
                              accent: .gray)
        }
    }

    private static func makeClockImage(size: CGSize, skin: SkinID, now: Date) -> UIImage {
        let palette = palette(for: skin)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            palette.bg.setFill()
            context.fill(rect)

            let timeText = ClockFormatters.shortTime.string(from: now)
            let dateText = "\(ClockFormatters.dateLine.string(from: now)) · \(ClockFormatters.weekday.string(from: now))"

            let timeAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 54, weight: .bold),
                .foregroundColor: palette.primary
            ]
            let dateAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: palette.accent
            ]
            let timeStr = NSAttributedString(string: timeText, attributes: timeAttr)
            let dateStr = NSAttributedString(string: dateText, attributes: dateAttr)

            let timeSize = timeStr.size()
            let dateSize = dateStr.size()
            let gap: CGFloat = 6
            let totalHeight = timeSize.height + gap + dateSize.height
            var y = (size.height - totalHeight) / 2

            let timeRect = CGRect(x: (size.width - timeSize.width) / 2,
                                  y: y,
                                  width: timeSize.width,
                                  height: timeSize.height)
            timeStr.draw(in: timeRect)
            y += timeSize.height + gap

            let dateRect = CGRect(x: (size.width - dateSize.width) / 2,
                                  y: y,
                                  width: dateSize.width,
                                  height: dateSize.height)
            dateStr.draw(in: dateRect)
        }
    }

    private static func makePixelBuffer(from image: UIImage) -> CVPixelBuffer? {
        guard let cgImage = image.cgImage else { return nil }
        let width = Int(image.size.width)
        let height = Int(image.size.height)

        var pixelBuffer: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault, width, height,
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return nil }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedFirst.rawValue
            | CGBitmapInfo.byteOrder32Little.rawValue
        guard let cgContext = CGContext(
            data: base,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo) else { return nil }

        cgContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return buffer
    }
}
