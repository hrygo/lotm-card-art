import LotmCardStudioCore

enum ArchiveCopy {
    static let archive = "秘史档案馆"
    static let pathways = "途径"
    static let localLibrary = "本机画册"
    static let recentDiscoveries = "最近收录"
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
        case "klein":
            return "克莱恩"
        case "audrey":
            return "奥黛丽"
        case nil, "":
            return "途径原型"
        default:
            return "关联角色"
        }
    }

    static func voiceTitle(for identity: CardIdentity) -> String {
        let name = identity.displayName.components(separatedBy: " · ").first ?? identity.displayName
        return "\(name)的声音"
    }
}
