import SwiftUI
import Foundation
import WorldOfMysteriesFeatures
import WorldOfMysteriesCore

@main
struct WorldOfMysteriesApp: App {
    var body: some Scene {
        WindowGroup("诡秘世界") {
            ArchiveRootView(
                speechClient: try? SpeechRailConfiguration.makeClient()
            )
            .frame(minWidth: 1180, minHeight: 760)
        }
        .defaultSize(width: 1280, height: 860)
        .windowResizability(.contentSize)

        Settings {
            SpeechRailSettingsView()
        }
    }
}
