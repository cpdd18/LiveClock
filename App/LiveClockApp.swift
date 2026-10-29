import SwiftUI

@main
struct LiveClockApp: App {
    @StateObject private var settings = ClockSettings.shared
    @StateObject private var manager = ClockActivityManager()
    @StateObject private var pipManager = PiPClockManager.shared

    var body: some Scene {
        WindowGroup {
            ClockContentView()
                .environmentObject(settings)
                .environmentObject(manager)
                .environmentObject(pipManager)
        }
    }
}
