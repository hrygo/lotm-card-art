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
            return "未播放"
        case .loading:
            return "正在准备声音"
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

private struct SpeechCacheKey: Hashable, Sendable {
    let lineID: String
    let contentDigest: String
    let voiceProfileID: String

    init(line: NarrativeLine, voiceProfileID: String) {
        lineID = line.id
        contentDigest = line.contentDigest
        self.voiceProfileID = voiceProfileID
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
    private var synthesizedAudioCache: [SpeechCacheKey: Data] = [:]

    public init(client: SpeechRailHTTPClient?) {
        self.client = client
    }

    public func awaken(card: AlbumCard) {
        guard let pack = card.narrative,
              let greeting = pack.playableLines.first(where: { $0.kind == .greeting })
        else {
            state = .failed("暂时没有可播放的台词")
            return
        }
        speak(greeting, voiceProfileID: pack.voiceProfileID)
    }

    /// 播放一个故事章节；已批准章节的完整正文只对应一次 TTS 请求。
    ///
    /// 章节是当前 SpeechRail 单段音频合约下的最小可定位单位，
    /// 不在客户端按句拆分，避免把多个合成结果拼接成不连贯的音色。
    public func playStory(_ chapter: StoryChapter, voiceProfileID: String) {
        guard chapter.line.isPlayable else {
            state = .failed("这段故事还在确认中")
            return
        }
        speak(chapter.line, voiceProfileID: voiceProfileID)
    }

    public func speak(_ line: NarrativeLine, voiceProfileID: String) {
        guard line.isPlayable else {
            state = .failed("这段文字还在确认中")
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

        let cacheKey = SpeechCacheKey(line: line, voiceProfileID: voiceProfileID)
        if let cachedAudio = synthesizedAudioCache[cacheKey] {
            requestTask = nil
            playSynthesizedAudio(cachedAudio, token: token)
            return
        }

        guard let client else {
            state = .failed("声音服务未连接")
            return
        }

        let speechRequest = SpeechRequest(input: line.text, voice: voiceProfileID)
        requestTask = Task { [weak self] in
            do {
                let data = try await client.synthesize(speechRequest)
                try Task.checkCancellation()
                guard let self else {
                    return
                }
                self.playSynthesizedAudio(data, token: token, cacheKey: cacheKey)
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

    private func playSynthesizedAudio(
        _ data: Data,
        token: Int,
        cacheKey: SpeechCacheKey? = nil
    ) {
        guard generation == token else {
            return
        }
        do {
            let audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer.delegate = self
            player = audioPlayer
            if let cacheKey {
                synthesizedAudioCache[cacheKey] = data
            }
            guard audioPlayer.play() else {
                state = .failed("声音无法播放")
                return
            }
            state = .playing
        } catch {
            state = .failed(Self.message(for: error))
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
            state = .failed("声音无法播放")
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
        // 停止只清理当前播放状态，保留已合成音频供再次开始时复用。
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
            return "声音服务密钥缺失，请在“语音设置”中配置"
        case SpeechRailCredentialError.authenticationCancelled:
            return "未完成安全验证，仍可阅读文字"
        case SpeechRailCredentialError.authenticationFailed:
            return "安全验证失败，仍可阅读文字"
        case SpeechRailCredentialError.writeFailed, SpeechRailCredentialError.verificationFailed:
            return "安全凭据设置失败，请重试"
        case SpeechRailConfigurationFileError.missing:
            return "声音服务密钥缺失，请在“语音设置”中配置"
        case SpeechRailConfigurationFileError.invalidData:
            return "声音服务设置无效，请在“语音设置”中重新保存"
        case SpeechRailConfigurationFileError.readFailed, SpeechRailConfigurationFileError.writeFailed:
            return "声音服务设置不可用，请检查文件权限"
        case SpeechRailError.inputTooLong:
            return "这段文字太长，暂时无法生成声音"
        case let SpeechRailError.httpStatus(status):
            switch status {
            case 401:
                return "声音服务密钥缺失或无效，请在“语音设置”中配置"
            case 403:
                return "声音服务拒绝了当前密钥"
            case 408:
                return "声音服务响应超时，仍可阅读文字"
            case 422:
                return "声音服务暂时无法处理这段文字，请稍后重试"
            case 500...599:
                return "声音服务暂时不可用，请稍后重试"
            default:
                return "声音服务请求失败，请稍后重试"
            }
        case SpeechRailError.transport:
            return "声音服务不可用"
        case SpeechRailError.invalidResponse, SpeechRailError.decoding:
            return "声音服务返回的声音无法使用"
        case SpeechRailError.nonLoopbackAddress:
            return "声音服务只能连接本机"
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
            self.state = flag ? .idle : .failed("声音播放失败")
        }
    }
}
