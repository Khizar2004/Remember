import SwiftUI

/// Utility for applying visual decay effects to text
struct TextDecayEffect {
    // Decay effect cache to avoid expensive recalculations
    private static var decayCache: [String: [String: String]] = [:]
    private static let cacheLimit = 30 // Limit cache size
    
    /// Compatibility method for existing code
    static func applyDecay(to text: String, level: Int) -> String {
        return applyVisualDecay(text, decay: level)
    }
    
    /// Returns opacity based on decay level
    static func opacityEffect(for decayLevel: Int) -> Double {
        let baseFactor = max(0.0, 1.0 - (Double(decayLevel) / 120.0))
        return max(baseFactor, 0.35) // Never go below 0.35 opacity
    }
    
    /// Returns color based on decay level
    static func colorForDecayLevel(_ decayLevel: Int) -> Color {
        switch decayLevel {
        case 0..<25:
            return GlitchTheme.terminalGreen
        case 25..<50:
            return GlitchTheme.glitchCyan
        case 50..<75:
            return GlitchTheme.glitchYellow
        case 75..<90:
            return GlitchTheme.glitchOrange
        default:
            return GlitchTheme.glitchRed
        }
    }
    
    /// Returns blur radius based on decay level
    static func blurEffect(for decayLevel: Int) -> CGFloat {
        return min(CGFloat(decayLevel) / 200, 0.5)
    }
    
    /// Returns jitter offset based on decay level
    static func jitterOffset(for decayLevel: Int) -> CGFloat {
        guard decayLevel > 85 else { return 0 }
        return CGFloat.random(in: -1.0...1.0)
    }
    
    /// Returns RGB split amount based on decay level
    static func rgbSplitAmount(for decayLevel: Int) -> CGFloat {
        if decayLevel > 95 { return 1.0 }
        if decayLevel > 90 { return min(CGFloat(decayLevel) / 60, 1.5) }
        return 0
    }
    
    /// Apply visual decay to a text string based on decay level
    static func applyVisualDecay(_ text: String, decay: Int, flickerPhase: UUID = UUID()) -> String {
        let cacheKey = "\(decay)_\(flickerPhase)"
        
        if let cached = decayCache[text]?[cacheKey] {
            return cached
        }
        
        if decayCache.count > cacheLimit {
            decayCache.removeAll()
        }
        
        var result = text
        let decayFactor = Double(decay) / 100.0
        
        let timeBasedFlicker = Int(Date().timeIntervalSince1970 * 1000) % 1000
        
        let redactionChars = ["█", "▓", "▒", "░", "■", "◼", "◾", "▪", "▇"]
        
        let primaryRedaction = redactionChars[timeBasedFlicker % redactionChars.count]
        let secondaryRedaction = redactionChars[(timeBasedFlicker + 2) % redactionChars.count]
        
        let glitchMoment = timeBasedFlicker % 200 < 20
        
        // Critical decay - heavy redaction (mostly obscured)
        if decay >= 95 {
            var processed = ""
            for (i, char) in text.enumerated() {
                if i % 10 == 0 || (char == " " && i % 5 == 0) {
                    processed.append(char)
                } else if i % 20 == 0 {
                    let glyphChars = ["¥", "§", "Æ", "¢", "Ø", "∆", "Ω", "π", "µ"]
                    processed.append(glyphChars[(i + timeBasedFlicker) % glyphChars.count])
                } else if glitchMoment && i % 7 == 0 {
                    let artifacts = ["0", "1", "/", "\\", "|", "~", "_"]
                    processed.append(artifacts[(i + timeBasedFlicker) % artifacts.count])
                } else {
                    processed.append((i + timeBasedFlicker) % 5 == 0 ? secondaryRedaction : primaryRedaction)
                }
            }
            result = processed
        }
        // High decay - partial redaction with some glitch characters
        else if decay >= 85 {
            var processed = ""
            for (i, char) in text.enumerated() {
                if i % 5 == 0 || char == " " || Double.random(in: 0...1) > 0.8 {
                    processed.append(char)
                } else if Double.random(in: 0...1) > 0.6 {
                    let glitchChars = ["#", "@", "$", "%", "&", "*", "!"]
                    processed.append(glitchChars[(i + timeBasedFlicker) % glitchChars.count])
                } else if glitchMoment && i % 8 == 0 {
                    processed.append(char)
                } else {
                    processed.append((i + timeBasedFlicker) % 4 == 0 ? secondaryRedaction : primaryRedaction)
                }
            }
            result = processed
        }
        // Medium decay - character corruption and slight redaction
        else if decay >= 75 {
            var processed = ""
            for (i, char) in text.enumerated() {
                let charString = String(char).lowercased()
                
                if charString == "a" && Double.random(in: 0...1) < decayFactor * 0.8 {
                    processed.append("4")
                } else if charString == "e" && Double.random(in: 0...1) < decayFactor * 0.8 {
                    processed.append("3")
                } else if charString == "i" && Double.random(in: 0...1) < decayFactor * 0.8 {
                    processed.append("1") 
                } else if charString == "o" && Double.random(in: 0...1) < decayFactor * 0.8 {
                    processed.append("0")
                } else if i % 8 == 0 && Double.random(in: 0...1) < decayFactor * 0.5 {
                    processed.append((i + timeBasedFlicker) % 3 == 0 ? secondaryRedaction : primaryRedaction)
                } else {
                    processed.append(char)
                }
            }
            result = processed
        }
        
        if decayCache[text] == nil {
            decayCache[text] = [:]
        }
        decayCache[text]?[cacheKey] = result
        
        return result
    }
} 