import Combine
import LotmCardStudioCore
import SwiftUI

@MainActor
public final class SpeechRailSettingsViewModel: ObservableObject {
    @Published public private(set) var state: SpeechRailConfigurationFileState
    @Published public var apiKeyInput = ""
    @Published public private(set) var isWorking = false
    @Published public private(set) var message: String?

    public let fileURL: URL

    private let store: SpeechRailConfigurationFileStore

    public init(store: SpeechRailConfigurationFileStore = SpeechRailConfigurationFileStore()) {
        self.store = store
        self.fileURL = store.fileURL
        self.state = store.state()
    }

    public func refresh() {
        state = store.state()
    }

    public func saveInput() {
        let value = apiKeyInput
        apiKeyInput = ""
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            message = "请输入 API key"
            return
        }
        guard !isWorking else { return }

        isWorking = true
        message = "正在保存本机配置文件"
        Task { [weak self] in
            guard let self else { return }
            do {
                try store.saveAPIKey(value)
                state = store.state()
                message = "已保存到本机配置文件"
            } catch {
                state = store.state()
                message = Self.message(for: error)
            }
            isWorking = false
        }
    }

    private static func message(for error: Error) -> String {
        switch error {
        case SpeechRailConfigurationFileError.invalidData:
            return "API key 不能为空，请重新输入"
        case SpeechRailConfigurationFileError.readFailed:
            return "配置文件无法读取，请检查文件权限"
        case SpeechRailConfigurationFileError.writeFailed:
            return "配置文件保存失败，请检查目录权限"
        case SpeechRailConfigurationFileError.missing:
            return "配置文件尚未创建，请输入 API key"
        default:
            return "配置文件保存失败，请重试"
        }
    }
}

public struct SpeechRailSettingsView: View {
    @StateObject private var viewModel: SpeechRailSettingsViewModel

    public init(store: SpeechRailConfigurationFileStore = SpeechRailConfigurationFileStore()) {
        _viewModel = StateObject(wrappedValue: SpeechRailSettingsViewModel(store: store))
    }

    public var body: some View {
        Form {
            Section("本机配置文件") {
                LabeledContent("SpeechRail") {
                    Label(viewModel.state.displayName, systemImage: viewModel.state.systemImage)
                        .foregroundStyle(viewModel.state.tint)
                }
                Text(viewModel.fileURL.path)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .accessibilityLabel("SpeechRail 配置文件路径")
                    .accessibilityValue(viewModel.fileURL.path)
                Button {
                    viewModel.refresh()
                } label: {
                    Label("刷新状态", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isWorking)
            }

            Section("API key") {
                SecureField("输入或粘贴 API key", text: $viewModel.apiKeyInput)
                    .textContentType(.password)
                Button("保存到配置文件") {
                    viewModel.saveInput()
                }
                .disabled(viewModel.isWorking || viewModel.apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Section {
                Text("此版本不读取旧钥匙串条目，也不需要输入登录钥匙串密码。API key 只保存到上面的本机文件，文件权限为 0600；远程合成前按需读取。正常启动、本地 WAV 播放和查看文字稿都不会读取 API key。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                if let message = viewModel.message {
                    Text(message)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.primary)
                        .accessibilityLabel("状态消息")
                        .accessibilityValue(message)
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(minWidth: 560, minHeight: 380)
        .navigationTitle("SpeechRail")
        .task {
            viewModel.refresh()
        }
    }
}

private extension SpeechRailConfigurationFileState {
    var displayName: String {
        switch self {
        case .configured:
            return "配置文件已就绪"
        case .missing:
            return "尚未配置"
        case .unavailable:
            return "配置文件不可用"
        }
    }

    var systemImage: String {
        switch self {
        case .configured:
            return "checkmark.shield"
        case .missing:
            return "doc.badge.plus"
        case .unavailable:
            return "exclamationmark.triangle"
        }
    }

    var tint: Color {
        switch self {
        case .configured:
            return ArchiveTheme.teal
        case .missing:
            return ArchiveTheme.amber
        case .unavailable:
            return ArchiveTheme.danger
        }
    }
}
