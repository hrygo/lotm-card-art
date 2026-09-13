import Foundation

public enum NarrativeKind: String, Codable, Hashable, Sendable {
    case greeting
    case catchphrase
    case story
}

public enum NarrativeSourceKind: String, Codable, Hashable, Sendable {
    case canon
    case interpretation
    case original
}

public enum NarrativeReview: Codable, Hashable, Sendable {
    case draft
    case approved(contentDigest: String)
    case rejected

    public var approvedDigest: String? {
        guard case let .approved(contentDigest) = self else {
            return nil
        }
        return contentDigest
    }
}

public struct NarrativeLine: Codable, Hashable, Sendable {
    public let id: String
    public let kind: NarrativeKind
    public let text: String
    public let sourceKind: NarrativeSourceKind
    public let review: NarrativeReview
    public let contentDigest: String
    public let audioResourceName: String?

    public init(
        id: String,
        kind: NarrativeKind,
        text: String,
        sourceKind: NarrativeSourceKind,
        review: NarrativeReview,
        contentDigest: String,
        audioResourceName: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.text = text
        self.sourceKind = sourceKind
        self.review = review
        self.contentDigest = contentDigest
        self.audioResourceName = audioResourceName
    }

    public var isPlayable: Bool {
        review.approvedDigest == contentDigest
    }
}

public struct StoryChapter: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let line: NarrativeLine

    public init(id: String, title: String, line: NarrativeLine) {
        self.id = id
        self.title = title
        self.line = line
    }
}

public struct NarrativePack: Codable, Hashable, Sendable {
    public let cardID: String
    public let voiceProfileID: String
    public let lines: [NarrativeLine]
    public let chapters: [StoryChapter]

    public init(
        cardID: String,
        voiceProfileID: String,
        lines: [NarrativeLine],
        chapters: [StoryChapter]
    ) {
        self.cardID = cardID
        self.voiceProfileID = voiceProfileID
        self.lines = lines
        self.chapters = chapters
    }

    public var playableLines: [NarrativeLine] {
        lines.filter(\.isPlayable)
    }

    public var readableChapters: [StoryChapter] {
        chapters
    }

    public var playableChapters: [StoryChapter] {
        chapters.filter { $0.line.isPlayable }
    }
}
