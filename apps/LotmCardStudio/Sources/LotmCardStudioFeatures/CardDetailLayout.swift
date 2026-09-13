import CoreGraphics

enum CardDetailMode: String, CaseIterable, Identifiable, Sendable {
    case identity
    case story

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .identity:
            return "身份"
        case .story:
            return "故事"
        }
    }
}

enum CardDetailLayout {
    static let contentMaximumWidth: CGFloat = 1240
    static let motionViewportSize = CGSize(width: 420, height: 630)
    static let cardSize = CGSize(width: 320, height: 480)
    static let horizontalSafeArea: CGFloat = 50
    static let verticalSafeArea: CGFloat = 75
    static let railMinimumWidth: CGFloat = 460
    static let railMaximumWidth: CGFloat = 760
    static let stageToRailGap: CGFloat = 32
    static let horizontalPadding: CGFloat = 40
    static let verticalPadding: CGFloat = 32

    static let twoColumnMinimumContentWidth =
        motionViewportSize.width + stageToRailGap + railMinimumWidth

    static func usesTwoColumns(for contentWidth: CGFloat) -> Bool {
        contentWidth >= twoColumnMinimumContentWidth
    }
}
