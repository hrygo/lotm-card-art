import Foundation
import XCTest
import LotmCardStudioCore
@testable import LotmCardStudioFeatures

@MainActor
final class SpeechRailSettingsViewModelTests: XCTestCase {
    func testSavingInputClearsSecretImmediately() async {
        let store = makeStore()
        let viewModel = SpeechRailSettingsViewModel(store: store)
        viewModel.apiKeyInput = "file-test-key"

        viewModel.saveInput()

        XCTAssertEqual(viewModel.apiKeyInput, "")
        await waitForCompletion(of: viewModel)
        XCTAssertEqual(viewModel.state, .configured)
        XCTAssertFalse(viewModel.message?.contains("file-test-key") == true)
    }

    func testSavingInputRefreshesConfiguredStateAfterWriting() async throws {
        let store = makeStore()
        let viewModel = SpeechRailSettingsViewModel(store: store)
        viewModel.apiKeyInput = "  configured-test-key  "

        viewModel.saveInput()
        await waitForCompletion(of: viewModel)

        XCTAssertEqual(viewModel.state, .configured)
        XCTAssertEqual(try store.readAPIKey(), "configured-test-key")
        XCTAssertEqual(viewModel.message, "已保存到本机配置文件")
    }

    func testEmptyInputKeepsMissingStateAndDoesNotWrite() async {
        let store = makeStore()
        let viewModel = SpeechRailSettingsViewModel(store: store)

        viewModel.saveInput()
        await waitForCompletion(of: viewModel)

        XCTAssertEqual(viewModel.state, .missing)
        XCTAssertEqual(viewModel.message, "请输入 API key")
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.fileURL.path))
    }

    private func makeStore() -> SpeechRailConfigurationFileStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LotmCardStudioSettingsTests-\(UUID().uuidString)")
        let fileURL = directory.appendingPathComponent("SpeechRail.json")
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return SpeechRailConfigurationFileStore(fileURL: fileURL)
    }

    private func waitForCompletion(of viewModel: SpeechRailSettingsViewModel) async {
        for _ in 0..<100 where viewModel.isWorking {
            await Task.yield()
        }
        XCTAssertFalse(viewModel.isWorking)
    }
}
