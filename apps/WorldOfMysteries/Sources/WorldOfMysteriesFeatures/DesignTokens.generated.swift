// 由 tools/design_tokens.py 生成，请勿手改。
// 事实源：config/design-tokens.json ｜ 合同说明：design/design-tokens.md
import SwiftUI

/// 全局设计 token（`config/design-tokens.json` 的 Swift 投影）。
public enum DesignTokens {
    /// 原始色板与语义色。引用型 token 通过 opacity 保持与事实源一致的叠加关系。
    public enum Palette {
        public static let aetherCore = SwiftUI.Color(red: 0.3, green: 0.68, blue: 0.63)
        public static let aetherDeep = SwiftUI.Color(red: 0.12, green: 0.25, blue: 0.24)
        public static let aetherLight = SwiftUI.Color(red: 0.635, green: 0.843, blue: 0.808)
        public static let artworkDivineDeep = SwiftUI.Color(red: 0.04, green: 0.08, blue: 0.13)
        public static let artworkDivineDusk = SwiftUI.Color(red: 0.08, green: 0.06, blue: 0.11)
        public static let borderAetherGlow = Palette.aetherLight.opacity(0.45)
        public static let borderBrassAccent = Palette.brassLuster.opacity(0.4)
        public static let borderBrassMuted = Palette.brassPatina.opacity(0.5)
        public static let borderSubtle = Palette.leatherElevated.opacity(0.65)
        public static let brassCore = SwiftUI.Color(red: 0.643, green: 0.573, blue: 0.455)
        public static let brassGleam = SwiftUI.Color(red: 0.82, green: 0.749, blue: 0.6)
        public static let brassLuster = SwiftUI.Color(red: 0.91, green: 0.824, blue: 0.631)
        public static let brassPatina = SwiftUI.Color(red: 0.431, green: 0.392, blue: 0.345)
        public static let leatherBase = SwiftUI.Color(red: 0.122, green: 0.114, blue: 0.118)
        public static let leatherDeep = SwiftUI.Color(red: 0.102, green: 0.094, blue: 0.102)
        public static let leatherElevated = SwiftUI.Color(red: 0.278, green: 0.267, blue: 0.255)
        public static let leatherHighlight = SwiftUI.Color(red: 0.38, green: 0.36, blue: 0.34)
        public static let leatherRaised = SwiftUI.Color(red: 0.18, green: 0.173, blue: 0.176)
        public static let leatherVoid = SwiftUI.Color(red: 0.016, green: 0.031, blue: 0.051)
        public static let mysticCrimson = SwiftUI.Color(red: 0.85, green: 0.33, blue: 0.33)
        public static let mysticIce = SwiftUI.Color(red: 0.52, green: 0.68, blue: 0.82)
        public static let mysticViolet = SwiftUI.Color(red: 0.52, green: 0.44, blue: 0.76)
        public static let parchmentMuted = SwiftUI.Color(red: 0.431, green: 0.392, blue: 0.345)
        public static let parchmentPrimary = SwiftUI.Color(red: 0.949, green: 0.937, blue: 0.914)
        public static let parchmentSecondary = SwiftUI.Color(red: 0.639, green: 0.62, blue: 0.576)
        public static let playbackFailed = Palette.mysticCrimson
        public static let playbackIdle = Palette.parchmentSecondary
        public static let playbackPreparing = Palette.brassGleam
        public static let playbackReady = Palette.aetherLight
        public static let semanticAbility = Palette.aetherLight
        public static let semanticActing = SwiftUI.Color(red: 0.86, green: 0.72, blue: 0.46)
        public static let semanticLimitation = Palette.mysticCrimson
        public static let semanticPotion = SwiftUI.Color(red: 0.8, green: 0.5, blue: 0.65)
        public static let semanticPromotion = SwiftUI.Color(red: 0.68, green: 0.55, blue: 0.36)
        public static let shadowAetherPulse = SwiftUI.Color(red: 0.635, green: 0.843, blue: 0.808).opacity(0.45)
        public static let shadowBrassGlow = SwiftUI.Color(red: 0.91, green: 0.824, blue: 0.631).opacity(0.38)
        public static let shadowLeatherPlinth = SwiftUI.Color(red: 0.016, green: 0.031, blue: 0.051).opacity(0.85)
        public static let statusCandidate = SwiftUI.Color(red: 0.72, green: 0.55, blue: 0.42)
        public static let statusConfirmed = Palette.aetherLight
        public static let statusUnfilled = SwiftUI.Color(red: 0.55, green: 0.51, blue: 0.47)
        public static let statusUnresearched = SwiftUI.Color(red: 0.62, green: 0.6, blue: 0.55)
        public static let storyEdge = Palette.brassGleam.opacity(0.58)
        public static let storyInk = Palette.parchmentPrimary
        public static let storyInkMuted = Palette.parchmentSecondary
        public static let storyPaper = SwiftUI.Color(red: 0.3, green: 0.26, blue: 0.205)
        public static let storyPaperHighlight = SwiftUI.Color(red: 0.87, green: 0.79, blue: 0.61)
        public static let storyShadow = Palette.leatherVoid.opacity(0.72)
        public static let tierAngelBorder = SwiftUI.Color(red: 0.44, green: 0.25, blue: 0.61)
        public static let tierAngelGlow = Palette.tierAngelLabel.opacity(0.34)
        public static let tierAngelLabel = SwiftUI.Color(red: 0.651, green: 0.42, blue: 0.839)
        public static let tierAngelSurface = Palette.tierAngelLabel.opacity(0.15)
        public static let tierLowBorder = SwiftUI.Color(red: 0.66, green: 0.71, blue: 0.76)
        public static let tierLowGlow = SwiftUI.Color(red: 0.84, green: 0.89, blue: 0.93).opacity(0.28)
        public static let tierLowLabel = SwiftUI.Color(red: 0.91, green: 0.929, blue: 0.949)
        public static let tierLowSurface = Palette.tierLowLabel.opacity(0.12)
        public static let tierMidBorder = SwiftUI.Color(red: 0.2, green: 0.51, blue: 0.32)
        public static let tierMidGlow = Palette.tierMidLabel.opacity(0.3)
        public static let tierMidLabel = SwiftUI.Color(red: 0.333, green: 0.725, blue: 0.471)
        public static let tierMidSurface = Palette.tierMidLabel.opacity(0.14)
        public static let tierSaintBorder = SwiftUI.Color(red: 0.18, green: 0.38, blue: 0.58)
        public static let tierSaintGlow = Palette.tierSaintLabel.opacity(0.32)
        public static let tierSaintLabel = SwiftUI.Color(red: 0.302, green: 0.592, blue: 0.831)
        public static let tierSaintSurface = Palette.tierSaintLabel.opacity(0.14)
        public static let tierTrueGodBorder = SwiftUI.Color(red: 0.72, green: 0.47, blue: 0.09)
        public static let tierTrueGodGlow = Palette.tierTrueGodLabel.opacity(0.38)
        public static let tierTrueGodLabel = SwiftUI.Color(red: 0.941, green: 0.698, blue: 0.247)
        public static let tierTrueGodSurface = Palette.tierTrueGodLabel.opacity(0.16)
        public static let tierUnknownBorder = Palette.borderSubtle
        public static let tierUnknownGlow = SwiftUI.Color(red: 0, green: 0, blue: 0).opacity(0)
        public static let tierUnknownLabel = Palette.parchmentSecondary
        public static let tierUnknownSurface = Palette.leatherElevated.opacity(0.1)
    }

    /// 间距刻度；数值即取值，不做二次归一。
    public enum Space {
        public static let s1: CGFloat = 1
        public static let s2: CGFloat = 2
        public static let s3: CGFloat = 3
        public static let s4: CGFloat = 4
        public static let s5: CGFloat = 5
        public static let s6: CGFloat = 6
        public static let s7: CGFloat = 7
        public static let s8: CGFloat = 8
        public static let s9: CGFloat = 9
        public static let s10: CGFloat = 10
        public static let s12: CGFloat = 12
        public static let s14: CGFloat = 14
        public static let s15: CGFloat = 15
        public static let s16: CGFloat = 16
        public static let s18: CGFloat = 18
        public static let s20: CGFloat = 20
        public static let s22: CGFloat = 22
        public static let s24: CGFloat = 24
        public static let s26: CGFloat = 26
        public static let s28: CGFloat = 28
        public static let s32: CGFloat = 32
        public static let s36: CGFloat = 36
        public static let s40: CGFloat = 40
        public static let s44: CGFloat = 44
        public static let s60: CGFloat = 60
        public static let s68: CGFloat = 68
        public static let s110: CGFloat = 110
    }

    /// 圆角；具名项是结构语义（卡片 / 面板 / 抽屉 / 芯片 / 侧栏条）。
    public enum Radius {
        public static let r6: CGFloat = 6
        public static let r8: CGFloat = 8
        public static let r10: CGFloat = 10
        public static let r12: CGFloat = 12
        public static let r14: CGFloat = 14
        public static let r16: CGFloat = 16
        public static let r17: CGFloat = 17
        public static let r18: CGFloat = 18
        public static let r20: CGFloat = 20
        public static let r22: CGFloat = 22
        public static let r28: CGFloat = 28
        public static let card: CGFloat = 14
        public static let panel: CGFloat = 18
        public static let sheet: CGFloat = 22
        public static let chip: CGFloat = 10
        public static let rail: CGFloat = 14
        public static let ridge: CGFloat = 1.5
    }

    /// 描边宽度。
    public enum Stroke {
        public static let hairline: CGFloat = 1
        public static let thin: CGFloat = 0.8
        public static let medium: CGFloat = 1.2
        public static let strong: CGFloat = 1.5
    }

    /// 字号；取值为事实源里的实际使用值。
    public enum FontSize {
        public static let s8: CGFloat = 8
        public static let s9: CGFloat = 9
        public static let s10: CGFloat = 10
        public static let s11: CGFloat = 11
        public static let s12: CGFloat = 12
        public static let s13: CGFloat = 13
        public static let s14: CGFloat = 14
        public static let s16: CGFloat = 16
        public static let s17: CGFloat = 17
        public static let s19: CGFloat = 19
        public static let s20: CGFloat = 20
        public static let s22: CGFloat = 22
        public static let s24: CGFloat = 24
        public static let s26: CGFloat = 26
        public static let s27: CGFloat = 27
        public static let s28: CGFloat = 28
        public static let s32: CGFloat = 32
        public static let s34: CGFloat = 34
    }

    /// 结构性尺寸（窗口、侧栏、命中区）。
    public enum Size {
        public static let sidebar: CGFloat = 266
        public static let sidebarMinimised: CGFloat = 232
        public static let chapterRail: CGFloat = 232
        public static let windowMinWidth: CGFloat = 1180
        public static let windowMinHeight: CGFloat = 760
        public static let hitTarget: CGFloat = 44
        public static let control: CGFloat = 34
        public static let controlSmall: CGFloat = 28
    }

    /// 动效时长与弹簧参数（Figma 里只能记说明，真实动效以代码为准）。
    public enum MotionDuration {
        public static let ms120: Double = 0.12
        public static let ms160: Double = 0.16
        public static let ms180: Double = 0.18
        public static let ms200: Double = 0.2
        public static let ms220: Double = 0.22
        public static let ms320: Double = 0.32
        public static let ms2800: Double = 2.8
    }
    public enum MotionSpring {
        public static var tactilePress: Spring { SwiftUI.Spring(response: 0.22, dampingRatio: 0.68) }
        public static var hover: Spring { SwiftUI.Spring(response: 0.32, dampingRatio: 0.78) }
    }
}
