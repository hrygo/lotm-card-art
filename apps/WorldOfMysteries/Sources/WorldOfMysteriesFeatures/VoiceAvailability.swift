import WorldOfMysteriesCore

enum VoiceAvailability: Equatable, Sendable {
    case pending
    case localAudio
    case speechRail

    var statusLabel: String {
        switch self {
        case .pending:
            return "等待确认"
        case .localAudio:
            return "可以播放"
        case .speechRail:
            return "可生成声音"
        }
    }

    var buttonHelp: String {
        switch self {
        case .pending:
            return "这张卡的台词还在确认中"
        case .localAudio:
            return "播放已经准备好的声音"
        case .speechRail:
            return "准备声音后播放已确认的台词"
        }
    }

    var accessibilityValue: String {
        switch self {
        case .pending:
            return "台词等待确认"
        case .localAudio:
            return "声音已准备好"
        case .speechRail:
            return "播放时准备声音"
        }
    }

    var captionPrompt: String {
        switch self {
        case .pending:
            return "台词确认后，声音和字幕会显示在这里。"
        case .localAudio:
            return "点击“播放声音”，当前台词会显示在这里。"
        case .speechRail:
            return "点击“播放声音”，会先准备声音，再显示台词。"
        }
    }
}

func voiceAvailability(for narrative: NarrativePack?) -> VoiceAvailability {
    guard let greeting = narrative?.playableLines.first(where: { $0.kind == .greeting }) else {
        return .pending
    }
    return greeting.audioResourceName == nil ? .speechRail : .localAudio
}
