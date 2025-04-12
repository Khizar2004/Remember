import SwiftUI

struct TextDecayEffect {
    
    /// Apply decay effect to text based on decay level
    /// - Parameters:
    ///   - text: Original text to decay
    ///   - decayLevel: Level of decay (0-100)
    /// - Returns: Decayed text
    static func applyDecay(to text: String, level decayLevel: Int) -> String {
        // Ensure valid decay level
        let validDecayLevel = max(0, min(decayLevel, 100))
        guard validDecayLevel > 0 else { return text }
        
        let decayFactor = Double(validDecayLevel) / 100.0
        
        var result = text
        
        // Character corruption
        if decayFactor > 0.2 {
            result = corruptCharacters(in: result, factor: decayFactor)
        }
        
        // Missing parts
        if decayFactor > 0.4 {
            result = createGaps(in: result, factor: decayFactor)
        }
        
        // Glitch text with random characters
        if decayFactor > 0.6 {
            result = addGlitchArtifacts(to: result, factor: decayFactor)
        }
        
        return result
    }
    
    // Replace some characters with similar looking ones
    private static func corruptCharacters(in text: String, factor: Double) -> String {
        let corruptionMap: [String: [String]] = [
            "a": ["4", "@", "a"],
            "e": ["3", "e", "e"],
            "i": ["1", "!", "i"],
            "o": ["0", "o", "o"],
            "s": ["5", "$", "s"],
            "t": ["+", "t", "t"],
            " ": [" ", "_", " "]
        ]
        
        let corruptionChance = min(factor * 0.5, 0.5) // Max 50% corruption at full decay
        
        return String(text.map { char in
            let charString = String(char).lowercased()
            if let possibleReplacements = corruptionMap[charString], 
               Double.random(in: 0...1) < corruptionChance {
                return Character(possibleReplacements.randomElement() ?? charString)
            }
            return char
        })
    }
    
    // Create gaps in text by replacing characters with spaces
    private static func createGaps(in text: String, factor: Double) -> String {
        let gapChance = min(factor * 0.3, 0.3) // Max 30% gaps at full decay
        
        return String(text.map { char in
            if Double.random(in: 0...1) < gapChance {
                return " "
            }
            return char
        })
    }
    
    // Add random glitch artifacts
    private static func addGlitchArtifacts(to text: String, factor: Double) -> String {
        let glitchChars = ["#", "!", "@", "$", "%", "&", "*", "=", "+", "-", "~", "`"]
        let glitchChance = min(factor * 0.2, 0.2) // Max 20% glitch artifacts at full decay
        
        var result = text
        let insertions = min(Int(Double(text.count) * glitchChance), text.count / 4)
        
        for _ in 0..<insertions {
            if let glitchChar = glitchChars.randomElement(),
               let randomIndex = result.indices.randomElement() {
                result.insert(contentsOf: String(glitchChar), at: randomIndex)
            }
        }
        
        return result
    }
    
    // Calculate the amount of blur to apply based on decay level
    static func blurEffect(for decayLevel: Int) -> Double {
        let validDecayLevel = max(0, min(decayLevel, 100))
        return min(Double(validDecayLevel) / 20.0, 5.0) // Max blur of 5.0 at full decay
    }
    
    // Calculate the opacity for text based on decay level
    static func opacityEffect(for decayLevel: Int) -> Double {
        let validDecayLevel = max(0, min(decayLevel, 100))
        return max(1.0 - (Double(validDecayLevel) / 200.0), 0.5) // Min opacity of 0.5 at full decay
    }
    
    // Create a jitter animation for the text
    static func jitterEffect(for decayLevel: Int) -> Animation? {
        let validDecayLevel = max(0, min(decayLevel, 100))
        guard validDecayLevel > 30 else { return nil }
        
        let intensity = Double(validDecayLevel) / 100.0
        let duration = 0.1 + (0.1 * intensity) // Fixed duration to avoid random values
        
        return Animation
            .easeInOut(duration: duration)
            .repeatForever(autoreverses: true)
    }
    
    // Calculate offset for jittering text
    static func jitterOffset(for decayLevel: Int) -> CGSize {
        let validDecayLevel = max(0, min(decayLevel, 100))
        guard validDecayLevel > 30 else { return .zero }
        
        let intensity = Double(validDecayLevel) / 100.0
        let maxOffset = min(intensity * 3.0, 3.0)
        
        // Fixed offsets to avoid potential NaN from random values
        return CGSize(
            width: maxOffset / 2.0,
            height: maxOffset / 2.0
        )
    }
} 