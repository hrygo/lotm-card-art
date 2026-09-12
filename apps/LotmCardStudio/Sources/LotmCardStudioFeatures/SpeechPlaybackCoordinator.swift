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

@MainActor
public final class SpeechPlaybackCoordinator: NSObject, ObservableObject {
    @Published public private(set) var state: PlaybackState = .idle
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
        requestTask?.cancel()
        player?.stop()
        generation += 1
        let token = generation
        currentLine = line
        currentVoiceProfileID = voiceProfileID
        currentText = line.text
        state = .loading

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
        currentText = nil
        state = .idle
    }

    private static func message(for error: Error) -> String {
        switch error {
        case SpeechRailError.inputTooLong:
            return "文本超过 SpeechRail 限制"
        case SpeechRailError.httpStatus:
            return "SpeechRail 合成失败"
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
