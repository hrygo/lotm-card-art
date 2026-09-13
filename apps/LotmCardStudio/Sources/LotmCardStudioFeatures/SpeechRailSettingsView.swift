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
            message = "请输入服务密钥"
            return
        }
        guard !isWorking else { return }

        isWorking = true
        message = "正在保存本机设置"
        Task { [weak self] in
            guard let self else { return }
            do {
                try store.saveAPIKey(value)
                state = store.state()
                message = "已保存到本机"
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
            return "服务密钥不能为空，请重新输入"
        case SpeechRailConfigurationFileError.readFailed:
            return "本机设置无法读取，请检查文件权限"
        case SpeechRailConfigurationFileError.writeFailed:
            return "本机设置保存失败，请检查目录权限"
        case SpeechRailConfigurationFileError.missing:
            return "还没有保存设置，请输入服务密钥"
        default:
            return "本机设置保存失败，请重试"
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
            Section("声音连接") {
                LabeledContent("语音服务") {
                    Label(viewModel.state.displayName, systemImage: viewModel.state.systemImage)
                        .foregroundStyle(viewModel.state.tint)
                }
                DisclosureGroup("高级信息") {
                    Text(viewModel.fileURL.path)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .accessibilityLabel("设置保存位置")
                        .accessibilityValue(viewModel.fileURL.path)
                }
                Button {
                    viewModel.refresh()
                } label: {
                    Label("刷新状态", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isWorking)
            }

            Section("声音服务密钥") {
                SecureField("输入或粘贴服务密钥", text: $viewModel.apiKeyInput)
                    .textContentType(.password)
                Button("保存到本机") {
                    viewModel.saveInput()
                }
                .disabled(viewModel.isWorking || viewModel.apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Section {
                Text("服务密钥只保存在本机，并在需要生成声音时使用。浏览画册、播放已准备好的声音和阅读故事都不需要它。")
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
        .navigationTitle("语音设置")
        .task {
            viewModel.refresh()
        }
    }
}

private extension SpeechRailConfigurationFileState {
    var displayName: String {
        switch self {
        case .configured:
            return "已配置"
        case .missing:
            return "尚未配置"
        case .unavailable:
            return "暂不可用"
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
