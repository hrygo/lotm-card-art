import Foundation

public enum CollectionIntent: String, Codable, Hashable, Sendable {
    case none
    case formal
    case candidate
}

public enum CollectionDisplayState: Equatable, Sendable {
    case uncollected
    case candidate
    case formal
    case upgradeAvailable
    case needsReview
}

public enum CollectionResolver {
    public static func resolve(
        intent: CollectionIntent,
        contentStatus: ContentStatus
    ) -> CollectionDisplayState {
        switch (intent, contentStatus) {
        case (.formal, .confirmed):
            return .formal
        case (.formal, _):
            return .needsReview
        case (.candidate, .confirmed):
            return .upgradeAvailable
        case (.candidate, _):
            return .candidate
        case (.none, _):
            return .uncollected
        }
    }
}

public struct CollectionProgress: Equatable, Sendable {
    public let confirmedCount: Int
    public let formalCount: Int
    public let denominator: Int
    public let fraction: Double?

    public static func confirmed(
        cards: [CardIdentity],
        formalCardIDs: Set<String>
    ) -> CollectionProgress {
        let confirmed = cards.filter { $0.contentStatus == .confirmed }
        let formal = confirmed.filter { formalCardIDs.contains($0.cardID) }
        return CollectionProgress(
            confirmedCount: confirmed.count,
            formalCount: formal.count,
            denominator: confirmed.count,
            fraction: confirmed.isEmpty ? nil : Double(formal.count) / Double(confirmed.count)
        )
    }
}
