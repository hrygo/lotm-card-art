import AVFoundation
import Combine
import LotmCardStudioCore

public enum PlaybackState: Equatable, Sendable {
    case idle
    case loading
    case playing
    case paused
    case failed(String)

    public var label: String {
        switch self {
        case .idle:
            return "待唤醒"
        case .loading:
            return "正在唤醒…"
        case .playing:
            return "正在播放"
        case .paused:
            return "已暂停"
        case let .failed(message):
            return message
        }
    }
}

public struct PlaybackCaption: Equatable, Sendable {
    public let lineID: String
    public let kind: NarrativeKind
    public let text: String

    public init(lineID: String, kind: NarrativeKind, text: String) {
        self.lineID = lineID
        self.kind = kind
        self.text = text
    }
}

@MainActor
public final class SpeechPlaybackCoordinator: NSObject, ObservableObject {
    @Published public private(set) var state: PlaybackState = .idle
    @Published public private(set) var currentCaption: PlaybackCaption?
    @Published public private(set) var currentText: String?

    private let client: SpeechRailHTTPClient?
    private var requestTask: Task<Void, Never>?
    private var player: AVAudioPlayer?
    private var generation = 0
    private var currentLine: NarrativeLine?
    private var currentVoiceProfileID: String?

    public init(client: SpeechRailHTTPClient?) {
        self.client = client
    }

    public func awaken(card: AlbumCard) {
        guard let pack = card.narrative,
              let greeting = pack.playableLines.first(where: { $0.kind == .greeting })
        else {
            state = .failed("暂无已批准台词")
            return
        }
        speak(greeting, voiceProfileID: pack.voiceProfileID)
    }

    public func playStory(_ chapter: StoryChapter, voiceProfileID: String) {
        guard chapter.line.isPlayable else {
            state = .failed("此章节尚未批准")
            return
        }
        speak(chapter.line, voiceProfileID: voiceProfileID)
    }

    public func speak(_ line: NarrativeLine, voiceProfileID: String) {
        guard line.isPlayable else {
            state = .failed("此内容尚未批准")
            return
        }

        requestTask?.cancel()
        player?.stop()
        generation += 1
        let token = generation
        currentLine = line
        currentVoiceProfileID = voiceProfileID
        currentCaption = PlaybackCaption(lineID: line.id, kind: line.kind, text: line.text)
        currentText = line.text
        state = .loading

        if playBundledAudio(for: line) {
            return
        }

        guard let client else {
            state = .failed("SpeechRail 未连接")
            return
        }

        requestTask = Task { [weak self] in
            do {
                let data = try await client.synthesize(
                    SpeechRequest(input: line.text, voice: voiceProfileID)
                )
                try Task.checkCancellation()
                guard let self, self.generation == token else {
                    return
                }
                let audioPlayer = try AVAudioPlayer(data: data)
                audioPlayer.delegate = self
                self.player = audioPlayer
                guard audioPlayer.play() else {
                    self.state = .failed("音频无法播放")
                    return
                }
                self.state = .playing
            } catch is CancellationError {
                return
            } catch {
                guard let self, self.generation == token else {
                    return
                }
                self.state = .failed(Self.message(for: error))
            }
        }
    }

    private func playBundledAudio(for line: NarrativeLine) -> Bool {
        guard let resourceName = line.audioResourceName,
              let url = Bundle.main.url(
                  forResource: resourceName,
                  withExtension: "wav",
                  subdirectory: "Audio"
              ),
              let data = try? Data(contentsOf: url),
              let audioPlayer = try? AVAudioPlayer(data: data)
        else {
            return false
        }

        audioPlayer.delegate = self
        player = audioPlayer
        guard audioPlayer.play() else {
            state = .failed("音频无法播放")
            return true
        }
        state = .playing
        return true
    }

    public func pause() {
        guard player?.isPlaying == true else {
            return
        }
        player?.pause()
        state = .paused
    }

    public func resume() {
        guard state == .paused, player?.play() == true else {
            return
        }
        state = .playing
    }

    public func replay() {
        guard let currentLine, let currentVoiceProfileID else {
            return
        }
        speak(currentLine, voiceProfileID: currentVoiceProfileID)
    }

    public func stop() {
        generation += 1
        requestTask?.cancel()
        requestTask = nil
        player?.stop()
        player = nil
        currentLine = nil
        currentVoiceProfileID = nil
        currentCaption = nil
        currentText = nil
        state = .idle
    }

    static func message(for error: Error) -> String {
        switch error {
        case SpeechRailCredentialError.missing, SpeechRailCredentialError.unavailable,
             SpeechRailCredentialError.invalidData:
            return "SpeechRail API key 缺失，请在设置中配置"
        case SpeechRailCredentialError.authenticationCancelled:
            return "未完成钥匙串认证，文字稿仍可阅读"
        case SpeechRailCredentialError.authenticationFailed:
            return "钥匙串认证失败，文字稿仍可阅读"
        case SpeechRailCredentialError.writeFailed, SpeechRailCredentialError.verificationFailed:
            return "Touch ID 凭据设置失败，请重试"
        case SpeechRailConfigurationFileError.missing:
            return "SpeechRail API key 缺失，请在设置中配置文件"
        case SpeechRailConfigurationFileError.invalidData:
            return "SpeechRail 配置文件无效，请在设置中重新保存"
        case SpeechRailConfigurationFileError.readFailed, SpeechRailConfigurationFileError.writeFailed:
            return "SpeechRail 配置文件不可用，请检查文件权限"
        case SpeechRailError.inputTooLong:
            return "文本超过 SpeechRail 限制"
        case let SpeechRailError.httpStatus(status):
            switch status {
            case 401:
                return "SpeechRail API key 缺失或无效，请在设置中配置"
            case 403:
                return "SpeechRail API key 无权访问"
            case 408:
                return "SpeechRail 请求超时，文字稿仍可阅读"
            case 422:
                return "SpeechRail 拒绝了当前语音请求，请检查 voice 或文本"
            case 500...599:
                return "SpeechRail 服务暂时不可用，请稍后重试"
            default:
                return "SpeechRail 请求失败（HTTP \(status)）"
            }
        case SpeechRailError.transport:
            return "SpeechRail 不可用"
        case SpeechRailError.invalidResponse, SpeechRailError.decoding:
            return "SpeechRail 返回无效音频"
        case SpeechRailError.nonLoopbackAddress:
            return "SpeechRail 地址不在本机"
        default:
            return "语音生成失败"
        }
    }
}

extension SpeechPlaybackCoordinator: AVAudioPlayerDelegate {
    nonisolated public func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        Task { @MainActor [weak self] in
            guard let self, self.state == .playing || self.state == .paused else {
                return
            }
            self.state = flag ? .idle : .failed("音频播放失败")
        }
    }
}
