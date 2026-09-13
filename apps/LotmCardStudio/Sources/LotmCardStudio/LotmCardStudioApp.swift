import SwiftUI
import Foundation
import LotmCardStudioFeatures
import LotmCardStudioCore

@main
struct LotmCardStudioApp: App {
    var body: some Scene {
        WindowGroup("诡秘卡牌画册") {
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
