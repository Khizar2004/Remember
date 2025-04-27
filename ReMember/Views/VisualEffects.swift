import SwiftUI

/// ScanlineOverlay provides a customizable scanline effect
struct ScanlineOverlay: View {
    enum OverlayType {
        case light
        case medium
        case heavy
    }
    
    let type: OverlayType
    
    var body: some View {
        let config = configForType(type)
        
        return VStack(spacing: config.spacing) {
            ForEach(0..<config.lineCount, id: \.self) { _ in
                Rectangle()
                    .fill(Color.white.opacity(config.opacity))
                    .frame(height: config.height)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func configForType(_ type: OverlayType) -> (lineCount: Int, spacing: CGFloat, height: CGFloat, opacity: Double) {
        switch type {
        case .light:
            return (lineCount: 30, spacing: 5, height: 1, opacity: 0.07)
        case .medium:
            return (lineCount: 40, spacing: 4, height: 1, opacity: 0.10)
        case .heavy:
            return (lineCount: 60, spacing: 3, height: 1, opacity: 0.15)
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .edgesIgnoringSafeArea(.all)
        
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.2))
                .frame(width: 200, height: 150)
                .overlay(
                    ScanlineOverlay(type: .light)
                        .blendMode(.overlay)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                )
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.2))
                .frame(width: 200, height: 150)
                .overlay(
                    ScanlineOverlay(type: .medium)
                        .blendMode(.overlay)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                )
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.2))
                .frame(width: 200, height: 150)
                .overlay(
                    ScanlineOverlay(type: .heavy)
                        .blendMode(.overlay)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                )
        }
    }
} 