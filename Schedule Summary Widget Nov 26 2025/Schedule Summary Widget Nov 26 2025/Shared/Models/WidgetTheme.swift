//
//  WidgetTheme.swift
//  AMF Schedule
//
//  Widget theming system with presets and custom photo backgrounds
//

import SwiftUI

// MARK: - Widget Theme

struct WidgetTheme: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var style: ThemeStyle
    
    // Colors
    var backgroundColor: ThemeColor
    var headerBackgroundColor: ThemeColor
    var primaryTextColor: ThemeColor
    var secondaryTextColor: ThemeColor
    var accentColor: ThemeColor
    
    // Font customization
    var headerFont: ThemeFont
    var bodyFont: ThemeFont
    
    // Transparency settings
    var useTransparentBackground: Bool
    var backgroundOpacity: Double  // 0.0 = fully transparent, 1.0 = fully opaque
    
    // Custom background image (stored as filename in App Group)
    var backgroundImageName: String?
    var backgroundImageOpacity: Double
    var backgroundImageBlur: Double
    var backgroundOverlayColor: ThemeColor?
    var backgroundOverlayOpacity: Double
    
    // MARK: - Codable with defaults for backwards compatibility
    
    enum CodingKeys: String, CodingKey {
        case id, name, style
        case backgroundColor, headerBackgroundColor, primaryTextColor, secondaryTextColor, accentColor
        case headerFont, bodyFont
        case useTransparentBackground, backgroundOpacity
        case backgroundImageName, backgroundImageOpacity, backgroundImageBlur
        case backgroundOverlayColor, backgroundOverlayOpacity
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        style = try container.decode(ThemeStyle.self, forKey: .style)
        
        backgroundColor = try container.decode(ThemeColor.self, forKey: .backgroundColor)
        headerBackgroundColor = try container.decode(ThemeColor.self, forKey: .headerBackgroundColor)
        primaryTextColor = try container.decode(ThemeColor.self, forKey: .primaryTextColor)
        secondaryTextColor = try container.decode(ThemeColor.self, forKey: .secondaryTextColor)
        accentColor = try container.decode(ThemeColor.self, forKey: .accentColor)
        
        // Fonts with defaults
        headerFont = try container.decodeIfPresent(ThemeFont.self, forKey: .headerFont) ?? ThemeFont(name: "Helvetica-Bold", size: 20)
        bodyFont = try container.decodeIfPresent(ThemeFont.self, forKey: .bodyFont) ?? ThemeFont(name: "HelveticaNeue", size: 11)
        
        // Transparency with defaults (NEW fields - backwards compatible)
        useTransparentBackground = try container.decodeIfPresent(Bool.self, forKey: .useTransparentBackground) ?? false
        backgroundOpacity = try container.decodeIfPresent(Double.self, forKey: .backgroundOpacity) ?? 1.0
        
        // Image settings with defaults
        backgroundImageName = try container.decodeIfPresent(String.self, forKey: .backgroundImageName)
        backgroundImageOpacity = try container.decodeIfPresent(Double.self, forKey: .backgroundImageOpacity) ?? 1.0
        backgroundImageBlur = try container.decodeIfPresent(Double.self, forKey: .backgroundImageBlur) ?? 0
        backgroundOverlayColor = try container.decodeIfPresent(ThemeColor.self, forKey: .backgroundOverlayColor)
        backgroundOverlayOpacity = try container.decodeIfPresent(Double.self, forKey: .backgroundOverlayOpacity) ?? 0.3
    }
    
    init(
        id: String,
        name: String,
        style: ThemeStyle = .light,
        backgroundColor: ThemeColor = ThemeColor(hex: "FFFFFF"),
        headerBackgroundColor: ThemeColor = ThemeColor(hex: "F5F5F5"),
        primaryTextColor: ThemeColor = ThemeColor(hex: "000000"),
        secondaryTextColor: ThemeColor = ThemeColor(hex: "666666"),
        accentColor: ThemeColor = ThemeColor(hex: "007AFF"),
        headerFont: ThemeFont = ThemeFont(name: "Helvetica-Bold", size: 20),
        bodyFont: ThemeFont = ThemeFont(name: "HelveticaNeue", size: 11),
        useTransparentBackground: Bool = false,
        backgroundOpacity: Double = 1.0,
        backgroundImageName: String? = nil,
        backgroundImageOpacity: Double = 1.0,
        backgroundImageBlur: Double = 0,
        backgroundOverlayColor: ThemeColor? = nil,
        backgroundOverlayOpacity: Double = 0.3
    ) {
        self.id = id
        self.name = name
        self.style = style
        self.backgroundColor = backgroundColor
        self.headerBackgroundColor = headerBackgroundColor
        self.primaryTextColor = primaryTextColor
        self.secondaryTextColor = secondaryTextColor
        self.accentColor = accentColor
        self.headerFont = headerFont
        self.bodyFont = bodyFont
        self.useTransparentBackground = useTransparentBackground
        self.backgroundOpacity = backgroundOpacity
        self.backgroundImageName = backgroundImageName
        self.backgroundImageOpacity = backgroundImageOpacity
        self.backgroundImageBlur = backgroundImageBlur
        self.backgroundOverlayColor = backgroundOverlayColor
        self.backgroundOverlayOpacity = backgroundOverlayOpacity
    }
}

// MARK: - Theme Font

struct ThemeFont: Codable, Equatable {
    var name: String
    var size: CGFloat
    
    var font: Font {
        .custom(name, size: size)
    }
    
    static let availableFonts: [String] = [
        "Helvetica-Bold",
        "Helvetica",
        "HelveticaNeue-Bold",
        "HelveticaNeue",
        "HelveticaNeue-Light",
        "Avenir-Heavy",
        "Avenir-Medium",
        "Avenir-Book",
        "AvenirNext-Bold",
        "AvenirNext-Medium",
        "AvenirNext-Regular",
        "Georgia-Bold",
        "Georgia",
        "TimesNewRomanPS-BoldMT",
        "TimesNewRomanPSMT",
        "Futura-Bold",
        "Futura-Medium",
        "GillSans-Bold",
        "GillSans",
        "Menlo-Bold",
        "Menlo-Regular",
        "SFProDisplay-Bold",
        "SFProDisplay-Regular",
        "SFProText-Bold",
        "SFProText-Regular",
        "NewYork-Bold",
        "NewYork-Regular"
    ]
}

// MARK: - Theme Style

enum ThemeStyle: String, Codable, CaseIterable {
    case light
    case dark
    case photo
    case system // Adapts to system light/dark mode
}

// MARK: - Theme Color (Codable wrapper)

struct ThemeColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double
    var isAdaptive: Bool // If true, uses system semantic colors
    var adaptiveType: AdaptiveColorType
    
    enum AdaptiveColorType: String, Codable {
        case none
        case primary    // System primary label color
        case secondary  // System secondary label color
    }
    
    init(hex: String, opacity: Double = 1.0) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        switch hex.count {
        case 3:
            self.red = Double((int >> 8) * 17) / 255
            self.green = Double((int >> 4 & 0xF) * 17) / 255
            self.blue = Double((int & 0xF) * 17) / 255
        case 6:
            self.red = Double(int >> 16) / 255
            self.green = Double(int >> 8 & 0xFF) / 255
            self.blue = Double(int & 0xFF) / 255
        default:
            self.red = 0
            self.green = 0
            self.blue = 0
        }
        self.opacity = opacity
        self.isAdaptive = false
        self.adaptiveType = .none
    }
    
    init(red: Double, green: Double, blue: Double, opacity: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
        self.isAdaptive = false
        self.adaptiveType = .none
    }
    
    // Adaptive colors that change with system appearance
    static var adaptivePrimary: ThemeColor {
        var color = ThemeColor(hex: "000000")
        color.isAdaptive = true
        color.adaptiveType = .primary
        return color
    }
    
    static var adaptiveSecondary: ThemeColor {
        var color = ThemeColor(hex: "666666")
        color.isAdaptive = true
        color.adaptiveType = .secondary
        return color
    }
    
    var color: Color {
        if isAdaptive {
            switch adaptiveType {
            case .primary:
                return Color.primary
            case .secondary:
                return Color.secondary
            case .none:
                return Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
            }
        }
        return Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
    
    var hexString: String {
        String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }
}

// MARK: - Preset Themes

extension WidgetTheme {
    
    // MARK: Light Themes
    
    static let classic = WidgetTheme(
        id: "classic",
        name: "System Default",
        style: .system, // Adapts to light/dark mode
        backgroundColor: ThemeColor(hex: "FFFFFF", opacity: 0), // Transparent - let system handle it
        headerBackgroundColor: ThemeColor(hex: "808080", opacity: 0.1), // Subtle adaptive header
        primaryTextColor: ThemeColor.adaptivePrimary, // Will use .primary color
        secondaryTextColor: ThemeColor.adaptiveSecondary, // Will use .secondary color
        accentColor: ThemeColor(hex: "007AFF"),
        useTransparentBackground: true // Use system's native background (Liquid Glass compatible)
    )
    
    static let solidWhite = WidgetTheme(
        id: "solidWhite",
        name: "Solid White",
        style: .light,
        backgroundColor: ThemeColor(hex: "FFFFFF"),
        headerBackgroundColor: ThemeColor(hex: "F5F5F5"),
        primaryTextColor: ThemeColor(hex: "000000"),
        secondaryTextColor: ThemeColor(hex: "666666"),
        accentColor: ThemeColor(hex: "007AFF"),
        useTransparentBackground: false // Explicitly solid
    )
    
    static let warmPaper = WidgetTheme(
        id: "warmPaper",
        name: "Warm Paper",
        style: .light,
        backgroundColor: ThemeColor(hex: "FBF8F3"),
        headerBackgroundColor: ThemeColor(hex: "F5F0E8"),
        primaryTextColor: ThemeColor(hex: "2C2416"),
        secondaryTextColor: ThemeColor(hex: "8B7355"),
        accentColor: ThemeColor(hex: "C4A574"),
        useTransparentBackground: false
    )
    
    static let coolMint = WidgetTheme(
        id: "coolMint",
        name: "Cool Mint",
        style: .light,
        backgroundColor: ThemeColor(hex: "F0F9F7"),
        headerBackgroundColor: ThemeColor(hex: "E3F2EE"),
        primaryTextColor: ThemeColor(hex: "1A3D36"),
        secondaryTextColor: ThemeColor(hex: "5A8B7D"),
        accentColor: ThemeColor(hex: "34C759")
    )
    
    static let roseQuartz = WidgetTheme(
        id: "roseQuartz",
        name: "Rose Quartz",
        style: .light,
        backgroundColor: ThemeColor(hex: "FDF6F6"),
        headerBackgroundColor: ThemeColor(hex: "F8ECEC"),
        primaryTextColor: ThemeColor(hex: "3D2A2A"),
        secondaryTextColor: ThemeColor(hex: "9E7B7B"),
        accentColor: ThemeColor(hex: "E8A0A0")
    )
    
    // MARK: Translucent Themes
    
    static let glassLight = WidgetTheme(
        id: "glassLight",
        name: "Glass Light",
        style: .light,
        backgroundColor: ThemeColor(hex: "FFFFFF", opacity: 0.7),
        headerBackgroundColor: ThemeColor(hex: "FFFFFF", opacity: 0.5),
        primaryTextColor: ThemeColor(hex: "000000"),
        secondaryTextColor: ThemeColor(hex: "333333"),
        accentColor: ThemeColor(hex: "007AFF"),
        useTransparentBackground: true,
        backgroundOpacity: 0.7
    )
    
    static let glassDark = WidgetTheme(
        id: "glassDark",
        name: "Glass Dark",
        style: .dark,
        backgroundColor: ThemeColor(hex: "000000", opacity: 0.6),
        headerBackgroundColor: ThemeColor(hex: "000000", opacity: 0.4),
        primaryTextColor: ThemeColor(hex: "FFFFFF"),
        secondaryTextColor: ThemeColor(hex: "CCCCCC"),
        accentColor: ThemeColor(hex: "0A84FF"),
        useTransparentBackground: true,
        backgroundOpacity: 0.6
    )
    
    static let frostedGlass = WidgetTheme(
        id: "frostedGlass",
        name: "Frosted",
        style: .light,
        backgroundColor: ThemeColor(hex: "F5F5F5", opacity: 0.85),
        headerBackgroundColor: ThemeColor(hex: "FFFFFF", opacity: 0.6),
        primaryTextColor: ThemeColor(hex: "1C1C1E"),
        secondaryTextColor: ThemeColor(hex: "48484A"),
        accentColor: ThemeColor(hex: "007AFF"),
        useTransparentBackground: true,
        backgroundOpacity: 0.85
    )
    
    static let clearVibrant = WidgetTheme(
        id: "clearVibrant",
        name: "Clear",
        style: .light,
        backgroundColor: ThemeColor(hex: "FFFFFF", opacity: 0.3),
        headerBackgroundColor: ThemeColor(hex: "FFFFFF", opacity: 0.2),
        primaryTextColor: ThemeColor(hex: "000000"),
        secondaryTextColor: ThemeColor(hex: "333333"),
        accentColor: ThemeColor(hex: "007AFF"),
        useTransparentBackground: true,
        backgroundOpacity: 0.3
    )
    
    // MARK: Dark Themes
    
    static let midnight = WidgetTheme(
        id: "midnight",
        name: "Midnight",
        style: .dark,
        backgroundColor: ThemeColor(hex: "000000"),
        headerBackgroundColor: ThemeColor(hex: "1C1C1E"),
        primaryTextColor: ThemeColor(hex: "FFFFFF"),
        secondaryTextColor: ThemeColor(hex: "8E8E93"),
        accentColor: ThemeColor(hex: "0A84FF")
    )
    
    static let charcoal = WidgetTheme(
        id: "charcoal",
        name: "Charcoal",
        style: .dark,
        backgroundColor: ThemeColor(hex: "1C1C1E"),
        headerBackgroundColor: ThemeColor(hex: "2C2C2E"),
        primaryTextColor: ThemeColor(hex: "FFFFFF"),
        secondaryTextColor: ThemeColor(hex: "ABABAB"),
        accentColor: ThemeColor(hex: "FF9F0A")
    )
    
    static let deepNavy = WidgetTheme(
        id: "deepNavy",
        name: "Deep Navy",
        style: .dark,
        backgroundColor: ThemeColor(hex: "0D1B2A"),
        headerBackgroundColor: ThemeColor(hex: "1B263B"),
        primaryTextColor: ThemeColor(hex: "E0E1DD"),
        secondaryTextColor: ThemeColor(hex: "778DA9"),
        accentColor: ThemeColor(hex: "00D4FF")
    )
    
    static let forestNight = WidgetTheme(
        id: "forestNight",
        name: "Forest Night",
        style: .dark,
        backgroundColor: ThemeColor(hex: "0D1F0D"),
        headerBackgroundColor: ThemeColor(hex: "1A2F1A"),
        primaryTextColor: ThemeColor(hex: "E8F5E8"),
        secondaryTextColor: ThemeColor(hex: "7DA67D"),
        accentColor: ThemeColor(hex: "4ADE80")
    )
    
    // MARK: Custom Photo Template
    
    static func photoTheme(imageName: String, isDark: Bool = false) -> WidgetTheme {
        WidgetTheme(
            id: "photo_\(imageName)",
            name: "Custom Photo",
            style: .photo,
            backgroundColor: isDark ? ThemeColor(hex: "000000") : ThemeColor(hex: "FFFFFF"),
            headerBackgroundColor: isDark ? ThemeColor(hex: "000000", opacity: 0.7) : ThemeColor(hex: "FFFFFF", opacity: 0.85),
            primaryTextColor: isDark ? ThemeColor(hex: "FFFFFF") : ThemeColor(hex: "000000"),
            secondaryTextColor: isDark ? ThemeColor(hex: "CCCCCC") : ThemeColor(hex: "555555"),
            accentColor: ThemeColor(hex: "007AFF"),
            backgroundImageName: imageName,
            backgroundImageOpacity: 1.0,
            backgroundImageBlur: 0,
            backgroundOverlayColor: isDark ? ThemeColor(hex: "000000") : ThemeColor(hex: "FFFFFF"),
            backgroundOverlayOpacity: isDark ? 0.4 : 0.3
        )
    }
    
    // MARK: All Presets
    
    static let allPresets: [WidgetTheme] = [
        .classic,
        .warmPaper,
        .coolMint,
        .roseQuartz,
        .glassLight,
        .glassDark,
        .frostedGlass,
        .clearVibrant,
        .midnight,
        .charcoal,
        .deepNavy,
        .forestNight
    ]
    
    static let lightPresets: [WidgetTheme] = [.classic, .solidWhite, .warmPaper, .coolMint, .roseQuartz]
    static let darkPresets: [WidgetTheme] = [.midnight, .charcoal, .deepNavy, .forestNight]
    static let translucentPresets: [WidgetTheme] = [.glassLight, .glassDark, .frostedGlass, .clearVibrant]
}

// MARK: - Rendering Helpers

extension WidgetTheme {
    /// Returns a Color that respects the current transparency settings.
    func surfaceColor(_ color: ThemeColor, opacityMultiplier: Double = 1.0) -> Color {
        guard useTransparentBackground else {
            return color.color
        }
        
        let opacity = max(0, min(1, backgroundOpacity * opacityMultiplier))
        if opacity == 0 {
            return Color.clear
        }
        return color.color.opacity(opacity)
    }
    
    var backgroundSurface: Color {
        surfaceColor(backgroundColor)
    }
    
    var headerSurface: Color {
        surfaceColor(headerBackgroundColor, opacityMultiplier: 0.85)
    }
    
    var glassTintColor: Color {
        switch style {
        case .dark:
            return Color.black
        default:
            return Color.white
        }
    }
}

// MARK: - Widget Themes Container (per-widget themes)

struct WidgetThemesConfig: Codable {
    var todayTheme: WidgetTheme
    var fiveDayTheme: WidgetTheme
    var nextWeekTheme: WidgetTheme
    
    static var `default`: WidgetThemesConfig {
        WidgetThemesConfig(
            todayTheme: .classic,
            fiveDayTheme: .classic,
            nextWeekTheme: .classic
        )
    }
    
    mutating func applyToAll(_ theme: WidgetTheme) {
        todayTheme = theme
        fiveDayTheme = theme
        nextWeekTheme = theme
    }
    
    func theme(for viewType: String) -> WidgetTheme {
        switch viewType {
        case "today": return todayTheme
        case "sevenDay": return fiveDayTheme
        case "nextWeek": return nextWeekTheme
        default: return todayTheme
        }
    }
}

