import Foundation

public enum ContentStatus: String, Codable, Hashable, Sendable {
    case unfilled
    case proposed
    case unresearched
    case confirmed
}

public enum IdentityKind: String, Codable, Hashable, Sendable {
    case character
    case archetype
}

public struct CardIdentity: Codable, Hashable, Sendable {
    public let cardID: String
    public let slotID: String
    public let displayName: String
    public let sequenceName: String
    public let contentStatus: ContentStatus
    public let identityKind: IdentityKind
    public let characterID: String?
    public let identitySliceID: String?

    public init(
        cardID: String,
        slotID: String,
        displayName: String,
        sequenceName: String,
        contentStatus: ContentStatus,
        identityKind: IdentityKind,
        characterID: String?,
        identitySliceID: String?
    ) {
        self.cardID = cardID
        self.slotID = slotID
        self.displayName = displayName
        self.sequenceName = sequenceName
        self.contentStatus = contentStatus
        self.identityKind = identityKind
        self.characterID = characterID
        self.identitySliceID = identitySliceID
    }

    public var hasValidIdentityBinding: Bool {
        switch identityKind {
        case .character:
            return !(characterID?.isEmpty ?? true) && !(identitySliceID?.isEmpty ?? true)
        case .archetype:
            return characterID == nil && identitySliceID == nil
        }
    }
}
