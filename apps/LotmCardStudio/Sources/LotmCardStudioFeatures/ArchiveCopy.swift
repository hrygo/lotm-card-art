import Foundation
import LotmCardStudioCore

enum ArchiveCopy {
    static let archive = "秘史档案馆"
    static let pathways = "途径"
    static let localLibrary = "本机画册"
    static let recentDiscoveries = "卡牌列表"
    static let wishlistMetricTitle = "愿望清单"
    static let identityInfo = "身份信息"
    static let characterRelation = "角色关联"
    static let voice = "声音"
    static let semanticReadback = "六维信息"
    static let story = "故事"
    static let chapters = "章节"

    static func sectionEyebrow(for section: LibrarySection) -> String {
        switch section {
        case .gallery:
            return "全部卡牌"
        case .formal:
            return "已收藏"
        case .candidate:
            return "候选卡牌"
        case .wishlist:
            return "愿望清单"
        }
    }

    static func pathwaySummary(confirmed: Int, candidate: Int) -> String {
        "\(confirmed) 张已确认 · \(candidate) 张候选"
    }

    static func characterName(for characterID: String?) -> String {
        switch characterID {
        case "klein-moretti":
            return "克莱恩·莫雷蒂"
        case "audrey":
            return "奥黛丽"
        case nil, "":
            return "途径原型"
        default:
            return "关联角色"
        }
    }

    static func characterRelationTitle(for characterID: String?) -> String {
        guard let characterID, !characterID.isEmpty else {
            return "身份类型"
        }
        return characterRelation
    }

    static func characterRelationNote(for characterID: String?) -> String? {
        guard let characterID, !characterID.isEmpty else {
            return "当前途径在该序列的通用原型卡，不对应具体角色。"
        }
        return nil
    }

    static func characterCountLabel(for characterID: String?, count: Int) -> String {
        guard let characterID, !characterID.isEmpty else {
            return "原型卡"
        }
        return "\(count) 张身份卡"
    }

    static func sequenceTier(for rawSequenceName: String) -> ArchiveTheme.Sequence.Tier {
        let parts = sequenceParts(from: rawSequenceName)
        let number = parts.first.flatMap { sequenceNumber(from: $0) }
        return ArchiveTheme.Sequence.Tier(sequenceNumber: number)
    }

    static func sequenceName(for rawSequenceName: String) -> String {
        let parts = sequenceParts(from: rawSequenceName)
        guard let first = parts.first, let number = sequenceNumber(from: first) else {
            return rawSequenceName
        }

        var displayParts = ["序列 \(number)"]
        displayParts.append(contentsOf: parts.dropFirst())
        return displayParts.joined(separator: " · ")
    }

    static func sequenceRankTitle(for rawSequenceName: String) -> String {
        switch sequenceTier(for: rawSequenceName) {
        case .low:
            return "低序列"
        case .mid:
            return "中序列"
        case .saint:
            return "圣者"
        case .angel:
            return "天使"
        case .trueGod:
            return "真神"
        case .unknown:
            return "未分级"
        }
    }

    static func sequenceDisplayLabel(
        for rawSequenceName: String,
        includesRank: Bool = false
    ) -> String {
        let displayName = sequenceName(for: rawSequenceName)
        guard includesRank, sequenceTier(for: rawSequenceName) != .unknown else {
            return displayName
        }

        let rankTitle = sequenceRankTitle(for: rawSequenceName)
        let displayParts = sequenceParts(from: displayName)
        guard !displayParts.dropFirst().contains(rankTitle) else {
            return displayName
        }
        return "\(displayName) · \(rankTitle)"
    }

    static func voiceTitle(for identity: CardIdentity) -> String {
        let name = identity.displayName.components(separatedBy: " · ").first ?? identity.displayName
        return "\(name)的声音"
    }

    private static func sequenceParts(from rawSequenceName: String) -> [String] {
        rawSequenceName
            .split(separator: "·", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    private static func sequenceNumber(from firstPart: String) -> Int? {
        guard firstPart.hasPrefix("序列") else {
            return nil
        }
        let rawNumber = firstPart.dropFirst("序列".count)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Int(rawNumber)
    }
}
