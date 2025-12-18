//
//  WidgetThemeStore.swift
//  AMF Schedule
//
//  Persists widget theme preferences to App Group storage
//

import SwiftUI
import WidgetKit

#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

final class WidgetThemeStore {
    
    static let shared = WidgetThemeStore()
    
    private let appGroupId = "group.Theo.Schedule-Summary-Widget-Nov-26-2025"
    private let themeFileName = "widgetTheme.json"
    private let themesConfigFileName = "widgetThemesConfig.json"
    private let imagesFolder = "BackgroundImages"
    
    private var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
    }
    
    private var themeFileURL: URL? {
        containerURL?.appendingPathComponent(themeFileName)
    }
    
    private var themesConfigURL: URL? {
        containerURL?.appendingPathComponent(themesConfigFileName)
    }
    
    private var imagesFolderURL: URL? {
        guard let url = containerURL?.appendingPathComponent(imagesFolder) else { return nil }
        
        // Create folder if needed
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }
    
    private init() {}
    
    // MARK: - Per-Widget Theme Persistence
    
    func saveThemesConfig(_ config: WidgetThemesConfig) {
        guard let url = themesConfigURL else {
            print("[WidgetThemeStore] ❌ No App Group container")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(config)
            try data.write(to: url, options: .atomic)
            print("[WidgetThemeStore] ✓ Saved themes config to: \(url.path)")
            print("[WidgetThemeStore] Today: \(config.todayTheme.name) (transparent: \(config.todayTheme.useTransparentBackground))")
            print("[WidgetThemeStore] 5-Day: \(config.fiveDayTheme.name)")
            print("[WidgetThemeStore] NextWeek: \(config.nextWeekTheme.name)")
            
            // Reload widget timelines to apply new themes
            WidgetCenter.shared.reloadAllTimelines()
            print("[WidgetThemeStore] ✓ Triggered widget refresh")
        } catch {
            print("[WidgetThemeStore] ❌ Failed to save themes config: \(error)")
        }
    }
    
    func loadThemesConfig() -> WidgetThemesConfig {
        guard let url = themesConfigURL,
              FileManager.default.fileExists(atPath: url.path) else {
            print("[WidgetThemeStore] No config file found, using default")
            return .default
        }
        
        do {
            let data = try Data(contentsOf: url)
            let config = try JSONDecoder().decode(WidgetThemesConfig.self, from: data)
            print("[WidgetThemeStore] ✓ Loaded themes config - Today: \(config.todayTheme.name), 5-Day: \(config.fiveDayTheme.name), NextWeek: \(config.nextWeekTheme.name)")
            return config
        } catch {
            print("[WidgetThemeStore] ❌ Failed to load themes config: \(error)")
            print("[WidgetThemeStore] Deleting corrupted config and starting fresh")
            // Delete the corrupted file and start fresh
            try? FileManager.default.removeItem(at: url)
            return .default
        }
    }
    
    // Force refresh widgets
    func forceRefreshWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        print("[WidgetThemeStore] ✓ Force refreshed all widgets")
    }
    
    // Clear all theme data (for debugging)
    func resetToDefaults() {
        if let url = themesConfigURL {
            try? FileManager.default.removeItem(at: url)
        }
        if let url = themeFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        WidgetCenter.shared.reloadAllTimelines()
        print("[WidgetThemeStore] ✓ Reset to defaults")
    }
    
    // MARK: - Legacy Single Theme (backwards compatibility)
    
    func saveTheme(_ theme: WidgetTheme) {
        guard let url = themeFileURL else {
            print("[WidgetThemeStore] ❌ No App Group container")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(theme)
            try data.write(to: url, options: .atomic)
            print("[WidgetThemeStore] ✓ Saved theme: \(theme.name)")
            
            // Reload widget timelines to apply new theme
            WidgetCenter.shared.reloadAllTimelines()
            print("[WidgetThemeStore] ✓ Triggered widget refresh")
        } catch {
            print("[WidgetThemeStore] ❌ Failed to save theme: \(error)")
        }
    }
    
    func loadTheme() -> WidgetTheme {
        // First try to load per-widget config
        let config = loadThemesConfig()
        return config.todayTheme // Default to today theme for backwards compatibility
    }
    
    func loadTheme(for viewType: String) -> WidgetTheme {
        let config = loadThemesConfig()
        return config.theme(for: viewType)
    }
    
    // MARK: - Background Image Storage
    
    func saveBackgroundImage(_ image: PlatformImage, withName name: String) -> String? {
        guard let folderURL = imagesFolderURL else {
            print("[WidgetThemeStore] ❌ No images folder")
            return nil
        }
        
        let fileName = "\(name)_\(UUID().uuidString.prefix(8)).jpg"
        let fileURL = folderURL.appendingPathComponent(fileName)
        
        // Resize image if too large (max 1200px on longest side for widgets)
        let resizedImage = resizeImageIfNeeded(image, maxDimension: 1200)
        
        // Compress with adaptive quality
        var compressionQuality: CGFloat = 0.8
        var data: Data?
        
        #if os(iOS)
        data = resizedImage.jpegData(compressionQuality: compressionQuality)
        // If still too large (>500KB), reduce quality further
        while let imageData = data, imageData.count > 500_000 && compressionQuality > 0.3 {
            compressionQuality -= 0.1
            data = resizedImage.jpegData(compressionQuality: compressionQuality)
            print("[WidgetThemeStore] Reducing quality to \(compressionQuality) - size: \(imageData.count / 1024)KB")
        }
        #elseif os(macOS)
        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            print("[WidgetThemeStore] ❌ Failed to convert NSImage to data")
            return nil
        }
        data = bitmapImage.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [NSBitmapImageRep.PropertyKey.compressionFactor: compressionQuality])
        // If still too large (>500KB), reduce quality further
        while let imageData = data, imageData.count > 500_000 && compressionQuality > 0.3 {
            compressionQuality -= 0.1
            data = bitmapImage.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [NSBitmapImageRep.PropertyKey.compressionFactor: compressionQuality])
            print("[WidgetThemeStore] Reducing quality to \(compressionQuality) - size: \(imageData.count / 1024)KB")
        }
        #endif
        
        guard let finalData = data else {
            print("[WidgetThemeStore] ❌ Failed to compress image")
            return nil
        }
        
        print("[WidgetThemeStore] Final image size: \(finalData.count / 1024)KB at quality \(compressionQuality)")
        
        do {
            try finalData.write(to: fileURL, options: .atomic)
            print("[WidgetThemeStore] ✓ Saved background image: \(fileName)")
            return fileName
        } catch {
            print("[WidgetThemeStore] ❌ Failed to save image: \(error)")
            return nil
        }
    }
    
    private func resizeImageIfNeeded(_ image: PlatformImage, maxDimension: CGFloat) -> PlatformImage {
        let size = image.size
        
        // Check if resize needed
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let ratio = size.width / size.height
        var newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / ratio)
        } else {
            newSize = CGSize(width: maxDimension * ratio, height: maxDimension)
        }
        
        print("[WidgetThemeStore] Resizing from \(Int(size.width))x\(Int(size.height)) to \(Int(newSize.width))x\(Int(newSize.height))")
        
        // Render resized image
        #if os(iOS)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized
        #elseif os(macOS)
        let resized = NSImage(size: newSize)
        resized.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize), from: NSRect(origin: .zero, size: image.size), operation: NSCompositingOperation.sourceOver, fraction: 1.0)
        resized.unlockFocus()
        return resized
        #endif
    }
    
    func loadBackgroundImage(named name: String) -> PlatformImage? {
        guard let folderURL = imagesFolderURL else { return nil }
        
        let fileURL = folderURL.appendingPathComponent(name)
        
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            print("[WidgetThemeStore] ❌ Background image not found: \(name)")
            return nil
        }
        
        #if os(iOS)
        return UIImage(data: data)
        #elseif os(macOS)
        return NSImage(data: data)
        #endif
    }
    
    func deleteBackgroundImage(named name: String) {
        guard let folderURL = imagesFolderURL else { return }
        
        let fileURL = folderURL.appendingPathComponent(name)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("[WidgetThemeStore] ✓ Deleted background image: \(name)")
        } catch {
            print("[WidgetThemeStore] ❌ Failed to delete image: \(error)")
        }
    }
    
    func listBackgroundImages() -> [String] {
        guard let folderURL = imagesFolderURL else { return [] }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
            return contents.filter { $0.hasSuffix(".jpg") || $0.hasSuffix(".png") }
        } catch {
            return []
        }
    }
    
    // MARK: - Cleanup
    
    func cleanupUnusedImages() {
        let config = loadThemesConfig()
        let activeImageNames = Set(
            [config.todayTheme.backgroundImageName,
             config.fiveDayTheme.backgroundImageName,
             config.nextWeekTheme.backgroundImageName].compactMap { $0 }
        )
        
        let savedImages = listBackgroundImages()
        
        for imageName in savedImages where !activeImageNames.contains(imageName) {
            deleteBackgroundImage(named: imageName)
        }
    }
}

// MARK: - SwiftUI Environment Key

struct WidgetThemeKey: EnvironmentKey {
    static let defaultValue: WidgetTheme = .classic
}

extension EnvironmentValues {
    var widgetTheme: WidgetTheme {
        get { self[WidgetThemeKey.self] }
        set { self[WidgetThemeKey.self] = newValue }
    }
}

