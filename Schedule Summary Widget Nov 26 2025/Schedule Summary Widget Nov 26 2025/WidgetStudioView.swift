//
//  WidgetStudioView.swift
//  AMF Schedule
//
//  Widget customization studio with theme gallery and photo backgrounds
//

#if os(iOS)
import SwiftUI
import PhotosUI
import Combine
import UIKit

struct WidgetStudioView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = WidgetStudioViewModel()
    @State private var showingPhotoPicker = false
    @State private var showingPhotoEditor = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var editingTheme: WidgetTheme = .classic
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Widget Selection - which widgets to apply to
                    widgetSelectionSection
                    
                    // Current Theme Preview
                    currentThemePreview
                    
                    // Light Themes Section
                    themeSection(title: "LIGHT THEMES", themes: WidgetTheme.lightPresets)
                    
                    // Translucent Themes Section
                    themeSection(title: "TRANSLUCENT / GLASS", themes: WidgetTheme.translucentPresets)
                    
                    // Dark Themes Section
                    themeSection(title: "DARK THEMES", themes: WidgetTheme.darkPresets)
                    
                    // Custom Photo Section
                    customPhotoSection
                    
                    // Advanced Customization Section
                    advancedCustomizationSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Widget Studio")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhotoItem) { _, newItem in
            if let newItem {
                Task {
                    await viewModel.loadPhoto(from: newItem)
                    showingPhotoEditor = true
                }
            }
        }
        .sheet(isPresented: $showingPhotoEditor) {
            if let image = viewModel.selectedImage {
                PhotoBackgroundEditorView(
                    image: image,
                    onSave: { editedImage, isDark, blur, overlayOpacity in
                        viewModel.savePhotoTheme(
                            image: editedImage,
                            isDark: isDark,
                            blur: blur,
                            overlayOpacity: overlayOpacity
                        )
                    }
                )
            }
        }
        .onAppear {
            editingTheme = viewModel.currentTheme
        }
        .onReceive(viewModel.$themesConfig) { _ in
            editingTheme = viewModel.currentTheme
        }
    }
    
    // MARK: - Widget Selection Section
    
    private var widgetSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("APPLY TO WIDGETS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                
                Spacer()
                
                Button("Select All") {
                    print("[WidgetStudio] Select All tapped")
                    viewModel.selectAllWidgets()
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.blue)
                .buttonStyle(.borderless)
            }
            
            HStack(spacing: 10) {
                ForEach(WidgetStudioViewModel.WidgetTarget.allCases) { target in
                    WidgetTargetChip(
                        target: target,
                        isSelected: viewModel.applyToWidgets.contains(target),
                        onTap: { viewModel.toggleWidget(target) }
                    )
                }
            }
            
            // Apply to All Button
            Button {
                print("[WidgetStudio] Apply button tapped")
                viewModel.applyCurrentThemeToAllSelected()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                    Text("Apply Current Theme to Selected Widgets")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .buttonStyle(.borderless)
            .padding(.top, 4)
        }
    }
    
    // MARK: - Current Theme Preview
    
    private var currentThemePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CURRENT THEME")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                
                Spacer()
                
                Button("Force Refresh") {
                    print("[WidgetStudio] Force Refresh tapped")
                    viewModel.forceRefresh()
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.blue)
                .buttonStyle(.borderless)
                
                if editingTheme.id != "classic" {
                    Button("Reset") {
                        print("[WidgetStudio] Reset tapped")
                        selectPreset(.classic)
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.red)
                    .buttonStyle(.borderless)
                }
            }
            
            // Large preview card
            WidgetPreviewCard(theme: editingTheme, size: .large)
                .frame(height: 180)
                .clipped()
                .allowsHitTesting(false) // Don't let preview intercept taps
        }
    }
    
    // MARK: - Theme Section
    
    private func themeSection(title: String, themes: [WidgetTheme]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(1)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(themes) { theme in
                        ThemeCard(
                            theme: theme,
                            isSelected: editingTheme.id == theme.id,
                            onSelect: {
                                selectPreset(theme)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Custom Photo Section
    
    private var customPhotoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CUSTOM PHOTO")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(1)
            
            Button {
                showingPhotoPicker = true
            } label: {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 20))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Choose from Photos")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Select an image and customize it")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(16)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            // Show current photo theme if active
            if editingTheme.style == .photo {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Custom photo background active")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Advanced Customization Section
    
    private var advancedCustomizationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ADVANCED CONTROLS")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(1)
            
            transparencyControls
            colorControls
            fontControls
        }
    }
    
    private var transparencyControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TRANSPARENCY")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(1)
            
            VStack(spacing: 16) {
                Toggle(isOn: transparentBinding) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Translucent Background")
                            .font(.system(size: 14, weight: .medium))
                        Text("Let the system Liquid Glass show through")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.blue)
                
                if editingTheme.useTransparentBackground {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Overlay Intensity")
                                .font(.system(size: 14))
                            Spacer()
                            Text("\(Int(editingTheme.backgroundOpacity * 100))%")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(value: opacityBinding, in: 0...0.6, step: 0.05)
                            .tint(.blue)
                        
                        HStack {
                            Text("Clear glass")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("Frosted")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    private var colorControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("COLORS")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(1)
            
            VStack(spacing: 12) {
                ColorPickerRow(title: "Background", color: colorBinding(\.backgroundColor))
                ColorPickerRow(title: "Header Background", color: colorBinding(\.headerBackgroundColor))
                ColorPickerRow(title: "Primary Text", color: colorBinding(\.primaryTextColor))
                ColorPickerRow(title: "Secondary Text", color: colorBinding(\.secondaryTextColor))
                ColorPickerRow(title: "Accent Color", color: colorBinding(\.accentColor))
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    private var fontControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("FONTS")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(1)
            
            VStack(spacing: 16) {
                FontPickerRow(title: "Header Font", selectedFont: fontBinding(\.headerFont))
                FontPickerRow(title: "Body Font", selectedFont: fontBinding(\.bodyFont))
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    private func selectPreset(_ theme: WidgetTheme) {
        editingTheme = theme
        viewModel.selectTheme(theme)
    }
    
    private func updateEditingTheme(_ update: (inout WidgetTheme) -> Void) {
        var theme = editingTheme
        update(&theme)
        editingTheme = theme
        viewModel.selectTheme(theme)
    }
    
    private var transparentBinding: Binding<Bool> {
        Binding(
            get: { editingTheme.useTransparentBackground },
            set: { newValue in
                updateEditingTheme { theme in
                    theme.useTransparentBackground = newValue
                    if newValue && theme.backgroundOpacity == 1.0 {
                        theme.backgroundOpacity = 0.3
                    }
                    if !newValue {
                        theme.backgroundOpacity = 1.0
                    }
                }
            }
        )
    }
    
    private var opacityBinding: Binding<Double> {
        Binding(
            get: { editingTheme.backgroundOpacity },
            set: { newValue in
                updateEditingTheme { theme in
                    theme.backgroundOpacity = newValue
                }
            }
        )
    }
    
    private func colorBinding(_ keyPath: WritableKeyPath<WidgetTheme, ThemeColor>) -> Binding<Color> {
        Binding(
            get: { editingTheme[keyPath: keyPath].color },
            set: { newValue in
                updateEditingTheme { theme in
                    theme[keyPath: keyPath] = ThemeColor(from: newValue)
                }
            }
        )
    }
    
    private func fontBinding(_ keyPath: WritableKeyPath<WidgetTheme, ThemeFont>) -> Binding<String> {
        Binding(
            get: { editingTheme[keyPath: keyPath].name },
            set: { newValue in
                updateEditingTheme { theme in
                    var font = theme[keyPath: keyPath]
                    font.name = newValue
                    theme[keyPath: keyPath] = font
                }
            }
        )
    }
}


// MARK: - Color Picker Row

struct ColorPickerRow: View {
    let title: String
    @Binding var color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
            
            Spacer()
            
            ColorPicker("", selection: $color, supportsOpacity: false)
                .labelsHidden()
        }
    }
}

// MARK: - Font Picker Row

struct FontPickerRow: View {
    let title: String
    @Binding var selectedFont: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ThemeFont.availableFonts, id: \.self) { fontName in
                        FontChip(
                            fontName: fontName,
                            isSelected: selectedFont == fontName,
                            onTap: { selectedFont = fontName }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Font Chip

struct FontChip: View {
    let fontName: String
    let isSelected: Bool
    let onTap: () -> Void
    
    private var displayName: String {
        // Shorten font name for display
        fontName
            .replacingOccurrences(of: "HelveticaNeue-", with: "HN ")
            .replacingOccurrences(of: "Helvetica-", with: "H ")
            .replacingOccurrences(of: "AvenirNext-", with: "AN ")
            .replacingOccurrences(of: "Avenir-", with: "Av ")
            .replacingOccurrences(of: "SFProDisplay-", with: "SF ")
            .replacingOccurrences(of: "SFProText-", with: "SF ")
            .replacingOccurrences(of: "TimesNewRomanPS", with: "Times")
            .replacingOccurrences(of: "-BoldMT", with: " Bold")
            .replacingOccurrences(of: "MT", with: "")
            .replacingOccurrences(of: "GillSans-", with: "Gill ")
            .replacingOccurrences(of: "Georgia-", with: "Geo ")
            .replacingOccurrences(of: "Futura-", with: "Fut ")
            .replacingOccurrences(of: "Menlo-", with: "Menlo ")
            .replacingOccurrences(of: "NewYork-", with: "NY ")
    }
    
    var body: some View {
        Button(action: onTap) {
            Text(displayName)
                .font(.custom(fontName, size: 12))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(UIColor.tertiarySystemGroupedBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ThemeColor Extension

extension ThemeColor {
    init(from color: Color) {
        // Convert SwiftUI Color to RGB components
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        self.red = Double(red)
        self.green = Double(green)
        self.blue = Double(blue)
        self.opacity = Double(alpha)
        self.isAdaptive = false
        self.adaptiveType = .none
    }
}

// MARK: - Theme Card

struct ThemeCard: View {
    let theme: WidgetTheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button {
            print("[ThemeCard] Selected theme: \(theme.name)")
            onSelect()
        } label: {
            VStack(spacing: 8) {
                // Mini preview
                ZStack {
                    if theme.useTransparentBackground {
                        TransparentPreviewBackdrop()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.backgroundSurface)
                    
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.headerSurface)
                            .frame(height: 24)
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(theme.accentColor.color)
                                .frame(width: 6, height: 6)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(theme.primaryTextColor.color.opacity(0.3))
                                .frame(height: 4)
                        }
                        .padding(.horizontal, 8)
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(theme.secondaryTextColor.color)
                                .frame(width: 6, height: 6)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(theme.primaryTextColor.color.opacity(0.2))
                                .frame(height: 4)
                        }
                        .padding(.horizontal, 8)
                        
                        Spacer()
                    }
                    .padding(8)
                }
                .frame(width: 100, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                
                // Theme name
                Text(theme.name)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.system(size: 16))
                } else {
                    Circle()
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 16, height: 16)
                }
            }
            .contentShape(Rectangle()) // Make entire area tappable
        }
        .buttonStyle(.borderless)
    }
}

// MARK: - Widget Preview Card

struct WidgetPreviewCard: View {
        let theme: WidgetTheme
        let size: PreviewSize
        
        enum PreviewSize {
            case small, large
        }
        
        var body: some View {
            ZStack {
                if theme.useTransparentBackground {
                    TransparentPreviewBackdrop()
                }
                
                // Background
                if let imageName = theme.backgroundImageName,
                   let image = WidgetThemeStore.shared.loadBackgroundImage(named: imageName) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .opacity(theme.backgroundImageOpacity)
                        .blur(radius: theme.backgroundImageBlur)
                    
                    // Overlay
                    if let overlayColor = theme.backgroundOverlayColor {
                        overlayColor.color.opacity(theme.backgroundOverlayOpacity)
                    }
                } else if !theme.useTransparentBackground || theme.backgroundOpacity > 0 {
                    theme.backgroundSurface
                }
                
                // Content preview
                VStack(alignment: .leading, spacing: 8) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TODAY")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(theme.accentColor.color)
                                .tracking(1)
                            
                            Text("WEDNESDAY, DEC 3")
                                .font(.custom("Helvetica-Bold", size: size == .large ? 16 : 12))
                                .foregroundStyle(theme.primaryTextColor.color)
                                .tracking(-1)
                            
                            Text("5 EVENTS")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(theme.secondaryTextColor.color)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 3) {
                                Image(systemName: "sun.max")
                                    .font(.system(size: 12))
                                Text("72°")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundStyle(theme.primaryTextColor.color)
                            
                            Text("Clear • H:78° L:65°")
                                .font(.system(size: 8))
                                .foregroundStyle(theme.secondaryTextColor.color)
                        }
                    }
                    .padding(10)
                    .background(theme.headerSurface)
                    .cornerRadius(8)
                    
                    // Sample events
                    ForEach(0..<3, id: \.self) { i in
                        HStack(spacing: 6) {
                            Circle()
                                .fill([Color.blue, Color.orange, Color.green][i])
                                .frame(width: 6, height: 6)
                            
                            Text(["10:00 AM", "2:30 PM", "5:00 PM"][i])
                                .font(.system(size: 9))
                                .foregroundStyle(theme.secondaryTextColor.color)
                            
                            Text(["Team Meeting", "Client Call", "Review"][i])
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(theme.primaryTextColor.color)
                            
                            Spacer()
                        }
                    }
                }
                .padding(12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
}

struct TransparentPreviewBackdrop: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.35, green: 0.42, blue: 0.95).opacity(0.85),
                Color(red: 0.98, green: 0.54, blue: 0.66).opacity(0.85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.15),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - View Model

@MainActor
class WidgetStudioViewModel: ObservableObject {
    @Published var themesConfig: WidgetThemesConfig
    @Published var selectedImage: UIImage?
    @Published var applyToWidgets: Set<WidgetTarget> = Set(WidgetTarget.allCases)
    
    enum WidgetTarget: String, CaseIterable, Identifiable {
        case today = "Today"
        case fiveDay = "5-Day"
        case nextWeek = "Next Week"
        
        var id: String { rawValue }
    }
    
    private let store = WidgetThemeStore.shared
    
    var currentTheme: WidgetTheme {
        themesConfig.todayTheme
    }
    
    init() {
        self.themesConfig = WidgetThemeStore.shared.loadThemesConfig()
        print("[WidgetStudioViewModel] Initialized with theme: \(themesConfig.todayTheme.name)")
    }
    
    func selectTheme(_ theme: WidgetTheme) {
        print("[WidgetStudioViewModel] selectTheme called: \(theme.name)")
        withAnimation(.easeInOut(duration: 0.2)) {
            if applyToWidgets.contains(.today) {
                themesConfig.todayTheme = theme
            }
            if applyToWidgets.contains(.fiveDay) {
                themesConfig.fiveDayTheme = theme
            }
            if applyToWidgets.contains(.nextWeek) {
                themesConfig.nextWeekTheme = theme
            }
        }
        store.saveThemesConfig(themesConfig)
    }
    
    func loadPhoto(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            return
        }
        
        await MainActor.run {
            self.selectedImage = image
        }
    }
    
    func savePhotoTheme(image: UIImage, isDark: Bool, blur: Double, overlayOpacity: Double) {
        print("[WidgetStudioViewModel] savePhotoTheme called")
        guard let imageName = store.saveBackgroundImage(image, withName: "custom") else {
            print("[WidgetStudioViewModel] Failed to save image")
            return
        }
        
        var theme = WidgetTheme.photoTheme(imageName: imageName, isDark: isDark)
        theme.backgroundImageBlur = blur
        theme.backgroundOverlayOpacity = overlayOpacity
        
        selectTheme(theme)
        store.cleanupUnusedImages()
    }
    
    func toggleWidget(_ target: WidgetTarget) {
        print("[WidgetStudioViewModel] toggleWidget: \(target.rawValue)")
        if applyToWidgets.contains(target) {
            applyToWidgets.remove(target)
        } else {
            applyToWidgets.insert(target)
        }
    }
    
    func selectAllWidgets() {
        print("[WidgetStudioViewModel] selectAllWidgets called")
        applyToWidgets = Set(WidgetTarget.allCases)
    }
    
    func applyCurrentThemeToAllSelected() {
        print("[WidgetStudioViewModel] applyCurrentThemeToAllSelected called")
        selectTheme(currentTheme)
    }
    
    func forceRefresh() {
        print("[WidgetStudioViewModel] forceRefresh called")
        store.saveThemesConfig(themesConfig)
        store.forceRefreshWidgets()
    }
}

// MARK: - Widget Target Chip

struct WidgetTargetChip: View {
    let target: WidgetStudioViewModel.WidgetTarget
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button {
            print("[WidgetTargetChip] Tapped: \(target.rawValue)")
            onTap()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? .blue : .secondary)
                
                Text(target.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.borderless)
    }
}
// MARK: - Preview

#Preview {
    WidgetStudioView()
}
#endif // os(iOS)
