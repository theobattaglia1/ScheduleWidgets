//
//  PhotoBackgroundEditorView.swift
//  AMF Schedule
//
//  Photo editor for widget backgrounds with crop, resize, and adjustment tools
//

#if os(iOS)
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

struct PhotoBackgroundEditorView: View {
    @Environment(\.dismiss) var dismiss
    
    let image: UIImage
    let onSave: (UIImage, Bool, Double, Double) -> Void
    
    // Editor state
    @State private var editedImage: UIImage
    @State private var isDarkMode = false
    @State private var blurAmount: Double = 0
    @State private var overlayOpacity: Double = 0.3
    @State private var brightness: Double = 0
    @State private var contrast: Double = 1
    @State private var saturation: Double = 1
    
    // Crop state
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    // Tab selection
    @State private var selectedTab: EditorTab = .style
    
    // For live preview of adjustments
    @State private var previewImage: UIImage
    
    enum EditorTab: String, CaseIterable {
        case style = "Style"
        case adjust = "Adjust"
        case crop = "Crop"
    }
    
    init(image: UIImage, onSave: @escaping (UIImage, Bool, Double, Double) -> Void) {
        self.image = image
        self.onSave = onSave
        self._editedImage = State(initialValue: image)
        self._previewImage = State(initialValue: image)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Preview area
                GeometryReader { geometry in
                    ZStack {
                        Color.black
                        
                        // Image with effects
                        imagePreview
                            .frame(width: geometry.size.width - 40, height: (geometry.size.width - 40) * 0.6)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                    }
                }
                .frame(height: 280)
                
                // Controls area
                VStack(spacing: 0) {
                    // Tab picker
                    Picker("Editor", selection: $selectedTab) {
                        ForEach(EditorTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Tab content
                    ScrollView {
                        switch selectedTab {
                        case .style:
                            styleControls
                        case .adjust:
                            adjustControls
                        case .crop:
                            cropControls
                        }
                    }
                    .padding(.top, 20)
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
            .navigationTitle("Edit Background")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyAndSave()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Image Preview
    
    private var imagePreview: some View {
        ZStack {
            Image(uiImage: previewImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .scaleEffect(scale)
                .offset(offset)
                .blur(radius: blurAmount)
            
            // Overlay
            (isDarkMode ? Color.black : Color.white)
                .opacity(overlayOpacity)
            
            // Sample widget content preview
            widgetContentPreview
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = CGSize(
                        width: value.translation.width,
                        height: value.translation.height
                    )
                }
        )
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    scale = max(1.0, min(3.0, value))
                }
        )
    }
    
    private var widgetContentPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(isDarkMode ? .white : Color.blue)
                        .tracking(1)
                    
                    Text("WEDNESDAY, DEC 3")
                        .font(.custom("Helvetica-Bold", size: 14))
                        .foregroundStyle(isDarkMode ? .white : .black)
                        .tracking(-1)
                }
                
                Spacer()
                
                HStack(spacing: 2) {
                    Image(systemName: "sun.max")
                        .font(.system(size: 10))
                    Text("72°")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(isDarkMode ? .white : .black)
            }
            .padding(8)
            .background((isDarkMode ? Color.black : Color.white).opacity(isDarkMode ? 0.7 : 0.85))
            .cornerRadius(6)
            
            // Sample events
            ForEach(0..<2, id: \.self) { i in
                HStack(spacing: 4) {
                    Circle()
                        .fill(i == 0 ? Color.blue : Color.orange)
                        .frame(width: 5, height: 5)
                    
                    Text(i == 0 ? "10:00" : "2:30")
                        .font(.system(size: 8))
                        .foregroundStyle(isDarkMode ? .white.opacity(0.7) : .black.opacity(0.6))
                    
                    Text(i == 0 ? "Meeting" : "Call")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(isDarkMode ? .white : .black)
                }
            }
            
            Spacer()
        }
        .padding(10)
    }
    
    // MARK: - Style Controls
    
    private var styleControls: some View {
        VStack(spacing: 20) {
            // Light/Dark mode toggle
            VStack(alignment: .leading, spacing: 12) {
                Text("TEXT STYLE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                
                HStack(spacing: 12) {
                    StyleOptionButton(
                        title: "Light Text",
                        subtitle: "For dark photos",
                        icon: "moon.fill",
                        isSelected: isDarkMode
                    ) {
                        withAnimation { isDarkMode = true }
                    }
                    
                    StyleOptionButton(
                        title: "Dark Text",
                        subtitle: "For light photos",
                        icon: "sun.max.fill",
                        isSelected: !isDarkMode
                    ) {
                        withAnimation { isDarkMode = false }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Blur slider
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("BLUR")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(1)
                    
                    Spacer()
                    
                    Text("\(Int(blurAmount))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $blurAmount, in: 0...20, step: 1)
                    .tint(.blue)
            }
            .padding(.horizontal, 20)
            
            // Overlay opacity
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("OVERLAY OPACITY")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(1)
                    
                    Spacer()
                    
                    Text("\(Int(overlayOpacity * 100))%")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $overlayOpacity, in: 0...0.8, step: 0.05)
                    .tint(.blue)
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Adjust Controls
    
    private var adjustControls: some View {
        VStack(spacing: 20) {
            // Brightness
            adjustmentSlider(
                title: "BRIGHTNESS",
                value: $brightness,
                range: -0.5...0.5,
                format: { "\(Int($0 * 100))%" }
            )
            .onChange(of: brightness) { _, _ in applyImageAdjustments() }
            
            // Contrast
            adjustmentSlider(
                title: "CONTRAST",
                value: $contrast,
                range: 0.5...1.5,
                format: { "\(Int($0 * 100))%" }
            )
            .onChange(of: contrast) { _, _ in applyImageAdjustments() }
            
            // Saturation
            adjustmentSlider(
                title: "SATURATION",
                value: $saturation,
                range: 0...2,
                format: { "\(Int($0 * 100))%" }
            )
            .onChange(of: saturation) { _, _ in applyImageAdjustments() }
            
            // Reset button
            Button {
                resetAdjustments()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset to Original")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.red)
            }
            .padding(.top, 8)
        }
        .padding(.bottom, 20)
    }
    
    private func adjustmentSlider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        format: (Double) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                
                Spacer()
                
                Text(format(value.wrappedValue))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Slider(value: value, in: range)
                .tint(.blue)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Crop Controls
    
    private var cropControls: some View {
        VStack(spacing: 20) {
            Text("Pinch and drag the image above to position it")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Aspect ratio presets
            VStack(alignment: .leading, spacing: 12) {
                Text("WIDGET SIZE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                
                HStack(spacing: 12) {
                    AspectRatioButton(title: "Large", ratio: "360×376", isSelected: true) {}
                    AspectRatioButton(title: "Medium", ratio: "360×169", isSelected: false) {}
                    AspectRatioButton(title: "Small", ratio: "169×169", isSelected: false) {}
                }
            }
            .padding(.horizontal, 20)
            
            // Zoom slider
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("ZOOM")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(1)
                    
                    Spacer()
                    
                    Text("\(Int(scale * 100))%")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $scale, in: 1...3, step: 0.1)
                    .tint(.blue)
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Actions
    
    private func applyImageAdjustments() {
        guard let ciImage = CIImage(image: image) else { return }
        
        let context = CIContext()
        
        // Apply color controls filter
        let filter = CIFilter.colorControls()
        filter.inputImage = ciImage
        filter.brightness = Float(brightness)
        filter.contrast = Float(contrast)
        filter.saturation = Float(saturation)
        
        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return
        }
        
        let adjusted = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        previewImage = adjusted
        editedImage = adjusted
    }
    
    private func resetAdjustments() {
        brightness = 0
        contrast = 1
        saturation = 1
        previewImage = image
        editedImage = image
    }
    
    private func applyAndSave() {
        // Crop the image to widget aspect ratio if needed
        let croppedImage = cropImageForWidget(editedImage)
        onSave(croppedImage, isDarkMode, blurAmount, overlayOpacity)
        dismiss()
    }
    
    private func cropImageForWidget(_ image: UIImage) -> UIImage {
        // Target aspect ratio for large widget (approximately 360:376)
        let targetRatio: CGFloat = 360.0 / 376.0
        
        let imageSize = image.size
        let imageRatio = imageSize.width / imageSize.height
        
        var cropRect: CGRect
        
        if imageRatio > targetRatio {
            // Image is wider - crop width
            let newWidth = imageSize.height * targetRatio
            let xOffset = (imageSize.width - newWidth) / 2
            cropRect = CGRect(x: xOffset, y: 0, width: newWidth, height: imageSize.height)
        } else {
            // Image is taller - crop height
            let newHeight = imageSize.width / targetRatio
            let yOffset = (imageSize.height - newHeight) / 2
            cropRect = CGRect(x: 0, y: yOffset, width: imageSize.width, height: newHeight)
        }
        
        // Apply scale factor for zoom
        let scaledRect = CGRect(
            x: cropRect.origin.x + (cropRect.width * (1 - 1/scale)) / 2,
            y: cropRect.origin.y + (cropRect.height * (1 - 1/scale)) / 2,
            width: cropRect.width / scale,
            height: cropRect.height / scale
        )
        
        guard let cgImage = image.cgImage?.cropping(to: scaledRect) else {
            return image
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

// MARK: - Style Option Button

struct StyleOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? .white : .primary)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.blue : Color(UIColor.secondarySystemGroupedBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Aspect Ratio Button

struct AspectRatioButton: View {
    let title: String
    let ratio: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(ratio)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue : Color(UIColor.secondarySystemGroupedBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    PhotoBackgroundEditorView(
        image: UIImage(systemName: "photo")!,
        onSave: { _, _, _, _ in }
    )
}
#endif // os(iOS)

