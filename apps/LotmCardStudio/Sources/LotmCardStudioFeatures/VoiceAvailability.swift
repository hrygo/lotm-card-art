import LotmCardStudioCore

enum VoiceAvailability: Equatable, Sendable {
    case pending
    case localAudio
    case speechRail

    var statusLabel: String {
        switch self {
        case .pending:
            return "待审批"
        case .localAudio:
            return "本地音频优先"
        case .speechRail:
            return "需要 SpeechRail"
        }
    }

    var buttonHelp: String {
        switch self {
        case .pending:
            return "文案尚未批准，暂不可播放"
        case .localAudio:
            return "优先播放已批准的本地问候音频"
        case .speechRail:
            return "通过 SpeechRail 合成并播放已批准问候"
        }
    }

    var accessibilityValue: String {
        switch self {
        case .pending:
            return "等待人工批准"
        case .localAudio:
            return "本地音频优先，缺失时需要 SpeechRail"
        case .speechRail:
            return "需要 SpeechRail 合成"
        }
    }

    var prompt: String {
        switch self {
        case .pending:
            return "文案待批准，批准后生成声音"
        case .localAudio:
            return "点击唤醒，优先播放本地音频；字幕会在这里出现"
        case .speechRail:
            return "点击唤醒，将通过 SpeechRail 合成；字幕会在这里出现"
        }
    }
}

func voiceAvailability(for narrative: NarrativePack?) -> VoiceAvailability {
    guard let greeting = narrative?.playableLines.first(where: { $0.kind == .greeting }) else {
        return .pending
    }
    return greeting.audioResourceName == nil ? .speechRail : .localAudio
}
