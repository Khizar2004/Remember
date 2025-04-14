import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: UserSettings
    
    // Use state variables to handle button actions locally
    @State private var selectedUnit: DecayTimeUnit
    
    // Initialize with current settings
    init() {
        _selectedUnit = State(initialValue: UserSettings.shared.decayTimeUnit)
    }
    
    var body: some View {
        ZStack {
            // Background - keep effects only on the background
            GlitchTheme.background
                .ignoresSafeArea()
                .digitalNoise(intensity: 0.05)
                .crtEffect(intensity: 0.3)
            
            // Content without effects to ensure controls are clickable
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        // Apply settings before dismissing
                        settings.decayTimeUnit = selectedUnit
                        
                        // Then dismiss
                        dismiss()
                        HapticFeedback.light()
                    }) {
                        Text("DONE")
                            .font(GlitchTheme.terminalFont(size: 16))
                            .foregroundColor(GlitchTheme.glitchCyan)
                            .padding(8) // Increase hit target
                    }
                    .contentShape(Rectangle()) // Make entire area tappable
                    .padding(.leading, 8)
                    
                    Spacer()
                    
                    Text("SETTINGS")
                        .font(GlitchTheme.terminalFont(size: 20))
                        .foregroundColor(GlitchTheme.glitchCyan)
                    
                    Spacer()
                    
                    // Empty view for symmetry
                    Text("")
                        .frame(width: 70, alignment: .trailing)
                        .padding(.trailing, 16)
                }
                .padding(.top, 16)
                .padding(.bottom, 20)
                
                // Settings content
                VStack(spacing: 24) {
                    // Memory Decay settings
                    VStack(spacing: 16) {
                        HStack {
                            Text("MEMORY DECAY")
                                .font(GlitchTheme.terminalFont(size: 18))
                                .foregroundColor(GlitchTheme.glitchCyan)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        // Custom time unit selector
                        VStack(spacing: 6) {
                            HStack {
                                Text("DECAY TIME UNIT")
                                    .font(GlitchTheme.terminalFont(size: 14))
                                    .foregroundColor(GlitchTheme.terminalGreen)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            // Custom buttons instead of standard picker
                            HStack(spacing: 0) {
                                // Days button
                                Button {
                                    // Update local state only, not UserDefaults
                                    selectedUnit = .days
                                    HapticFeedback.light()
                                } label: {
                                    Text("DAYS")
                                        .font(GlitchTheme.terminalFont(size: 18))
                                        .foregroundColor(selectedUnit == .days ? 
                                                         GlitchTheme.background : 
                                                         GlitchTheme.terminalGreen)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(
                                            selectedUnit == .days ?
                                            GlitchTheme.glitchCyan :
                                            GlitchTheme.fieldBackground
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(GlitchTheme.glitchCyan.opacity(0.5), lineWidth: 1)
                                        )
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Hours button
                                Button {
                                    // Update local state only, not UserDefaults
                                    selectedUnit = .hours
                                    HapticFeedback.light()
                                } label: {
                                    Text("HOURS")
                                        .font(GlitchTheme.terminalFont(size: 18))
                                        .foregroundColor(selectedUnit == .hours ? 
                                                         GlitchTheme.background : 
                                                         GlitchTheme.terminalGreen)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(
                                            selectedUnit == .hours ?
                                            GlitchTheme.glitchCyan :
                                            GlitchTheme.fieldBackground
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(GlitchTheme.glitchCyan.opacity(0.5), lineWidth: 1)
                                        )
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .cornerRadius(4)
                            .padding(.horizontal, 20)
                            
                            // Description text with better styling
                            Text("Selecting HOURS will make memories decay faster than DAYS.")
                                .font(GlitchTheme.pixelFont(size: 14))
                                .foregroundColor(GlitchTheme.glitchYellow)
                                .padding(.top, 8)
                                .padding(.horizontal, 20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Decay info
                        VStack(spacing: 12) {
                            // Decay rates explainer
                            VStack(spacing: 10) {
                                HStack {
                                    Text("DECAY RATES")
                                        .font(GlitchTheme.terminalFont(size: 14))
                                        .foregroundColor(GlitchTheme.terminalGreen)
                                    Spacer()
                                }
                                
                                Divider()
                                    .background(GlitchTheme.glitchCyan.opacity(0.3))
                                
                                // Decay rate examples
                                VStack(spacing: 12) {
                                    makeDecayRateRow(
                                        label: selectedUnit == .days ? "1 DAY:" : "1 HOUR:",
                                        value: "5%", 
                                        color: .green
                                    )
                                    
                                    makeDecayRateRow(
                                        label: selectedUnit == .days ? "5 DAYS:" : "5 HOURS:",
                                        value: "25%", 
                                        color: .yellow
                                    )
                                    
                                    makeDecayRateRow(
                                        label: selectedUnit == .days ? "10 DAYS:" : "10 HOURS:",
                                        value: "50%", 
                                        color: .orange
                                    )
                                    
                                    makeDecayRateRow(
                                        label: selectedUnit == .days ? "20 DAYS:" : "20 HOURS:",
                                        value: "100%", 
                                        color: .red
                                    )
                                }
                            }
                            .padding(16)
                            .background(GlitchTheme.fieldBackground)
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(GlitchTheme.glitchCyan.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            HapticFeedback.light()
        }
        .onDisappear {
            // Save changes when view disappears
            settings.decayTimeUnit = selectedUnit
        }
    }
    
    // Helper to create consistent decay rate rows
    private func makeDecayRateRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(GlitchTheme.pixelFont(size: 14))
                .foregroundColor(GlitchTheme.terminalGreen)
            
            Spacer()
            
            Text(value)
                .font(GlitchTheme.pixelFont(size: 14))
                .foregroundColor(color)
        }
    }
} 