import Foundation
import CoreGraphics

enum CropStrength: String, Codable, CaseIterable, Identifiable, Equatable, Sendable {
    case light = "Light"
    case normal = "Normal"
    case maximum = "Maximum"
    var id: String { rawValue }
}

enum ReaderFitMode: String, Codable, CaseIterable, Identifiable, Equatable, Sendable {
    case fitPage = "Fit Page"
    case fitWidth = "Fit Width"
    var id: String { rawValue }
}

enum ReaderPageLayout: String, Codable, CaseIterable, Identifiable, Equatable, Sendable {
    case automatic = "Automatic"
    case single = "Single Page"
    case double = "Two Pages"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .automatic: return "rectangle.split.2x1"
        case .single: return "rectangle.portrait"
        case .double: return "rectangle.split.2x1.fill"
        }
    }
}


enum ComicEnhancePreset: String, Codable, CaseIterable, Identifiable, Equatable, Sendable {
    case off = "Off"
    case clarity = "Clarity"
    case vivid = "Vivid"
    case ink = "Ink"
    case soft = "Soft"

    var id: String { rawValue }

    var contrast: Double {
        switch self {
        case .off: return 1.0
        case .clarity: return 1.13
        case .vivid: return 1.08
        case .ink: return 1.34
        case .soft: return 0.96
        }
    }

    var brightness: Double {
        switch self {
        case .off, .clarity, .vivid: return 0
        case .ink: return 0.015
        case .soft: return 0.025
        }
    }

    var saturation: Double {
        switch self {
        case .off, .clarity: return 1.0
        case .vivid: return 1.18
        case .ink: return 0.12
        case .soft: return 0.94
        }
    }

    var grayscale: Double {
        switch self {
        case .ink: return 0.78
        default: return 0
        }
    }

    var systemImage: String {
        switch self {
        case .off: return "circle"
        case .clarity: return "circle.lefthalf.filled"
        case .vivid: return "sparkles"
        case .ink: return "drop.halffull"
        case .soft: return "sun.haze"
        }
    }
}

enum ReaderTranslationLanguage: String, Codable, CaseIterable, Identifiable, Equatable, Sendable {
    case turkish = "Turkish"
    case english = "English"
    case italian = "Italian"
    case german = "German"
    case french = "French"
    case spanish = "Spanish"
    case portuguese = "Portuguese"
    case japanese = "Japanese"
    case korean = "Korean"

    var id: String { rawValue }

    var localeIdentifier: String {
        switch self {
        case .turkish: return "tr"
        case .english: return "en"
        case .italian: return "it"
        case .german: return "de"
        case .french: return "fr"
        case .spanish: return "es"
        case .portuguese: return "pt"
        case .japanese: return "ja"
        case .korean: return "ko"
        }
    }
}

enum ReaderPageGap: String, Codable, CaseIterable, Identifiable, Equatable, Sendable {
    case none = "None"
    case small = "Small"
    case normal = "Normal"
    var id: String { rawValue }

    var points: CGFloat {
        switch self {
        case .none: return 0
        case .small: return 6
        case .normal: return 14
        }
    }
}

struct ManualCropInsets: Codable, Equatable, Sendable {
    var top: Double = 0
    var leading: Double = 0
    var bottom: Double = 0
    var trailing: Double = 0

    var isZero: Bool { top == 0 && leading == 0 && bottom == 0 && trailing == 0 }
}

struct ReaderSettings: Codable, Equatable, Sendable {
    var theme: ReaderTheme = .normal
    var autoCropEnabled: Bool = true
    var cropStrength: CropStrength = .normal
    var trimWebFooter: Bool = true
    var fullBleed: Bool = true
    var fitMode: ReaderFitMode = .fitWidth
    var pageLayout: ReaderPageLayout = .automatic
    var pageGap: ReaderPageGap = .none
    var autoHideControls: Bool = false
    var skipInitialPages: Int = 0
    var manualCrop: ManualCropInsets = ManualCropInsets()

    // Stage 17 — visual processing never rewrites the original comic.
    var enhancePreset: ComicEnhancePreset = .off

    // Desktop comfort and accessibility.
    var largeControls: Bool = false
    var highContrastControls: Bool = false
    var reduceReaderMotion: Bool = false

    // Page language tools.
    var translationTarget: ReaderTranslationLanguage = .turkish

    enum CodingKeys: String, CodingKey {
        case theme
        case autoCropEnabled
        case cropStrength
        case trimWebFooter
        case fullBleed
        case fitMode
        case pageLayout
        case pageGap
        case autoHideControls
        case skipInitialPages
        case manualCrop
        case enhancePreset
        case largeControls
        case highContrastControls
        case reduceReaderMotion
        case translationTarget
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        theme = try c.decodeIfPresent(ReaderTheme.self, forKey: .theme) ?? .normal
        autoCropEnabled = try c.decodeIfPresent(Bool.self, forKey: .autoCropEnabled) ?? true
        cropStrength = try c.decodeIfPresent(CropStrength.self, forKey: .cropStrength) ?? .normal
        trimWebFooter = try c.decodeIfPresent(Bool.self, forKey: .trimWebFooter) ?? true
        fullBleed = try c.decodeIfPresent(Bool.self, forKey: .fullBleed) ?? true
        fitMode = try c.decodeIfPresent(ReaderFitMode.self, forKey: .fitMode) ?? .fitWidth
        pageLayout = try c.decodeIfPresent(ReaderPageLayout.self, forKey: .pageLayout) ?? .automatic
        pageGap = try c.decodeIfPresent(ReaderPageGap.self, forKey: .pageGap) ?? .none
        autoHideControls = try c.decodeIfPresent(Bool.self, forKey: .autoHideControls) ?? false
        skipInitialPages = try c.decodeIfPresent(Int.self, forKey: .skipInitialPages) ?? 0
        manualCrop = try c.decodeIfPresent(ManualCropInsets.self, forKey: .manualCrop) ?? ManualCropInsets()
        enhancePreset = try c.decodeIfPresent(ComicEnhancePreset.self, forKey: .enhancePreset) ?? .off
        largeControls = try c.decodeIfPresent(Bool.self, forKey: .largeControls) ?? false
        highContrastControls = try c.decodeIfPresent(Bool.self, forKey: .highContrastControls) ?? false
        reduceReaderMotion = try c.decodeIfPresent(Bool.self, forKey: .reduceReaderMotion) ?? false
        translationTarget = try c.decodeIfPresent(ReaderTranslationLanguage.self, forKey: .translationTarget) ?? .turkish
    }
}
