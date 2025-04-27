import SwiftUI

struct TextDecayEffect {
    
    // Cache for processed text to avoid recalculating
    private static var textCache: [String: [Int: String]] = [:]
    private static let cacheLimit = 100
    
    /// Apply decay effect to text based on decay level
    /// - Parameters:
    ///   - text: Original text to decay
    ///   - decayLevel: Level of decay (0-100)
    /// - Returns: Decayed text
    static func applyDecay(to text: String, level decayLevel: Int) -> String {
        // Ensure valid decay level
        let validDecayLevel = max(0, min(decayLevel, 100))
        guard validDecayLevel > 0 else { return text }
        
        // Return cached result if available
        if let cachedResults = textCache[text], let cachedText = cachedResults[validDecayLevel] {
            return cachedText
        }
        
        // For very long texts, only process the first 300 characters
        let processText = text.count > 300 ? String(text.prefix(300)) + "..." : text
        let decayFactor = Double(validDecayLevel) / 100.0
        
        var result = processText
        
        // Character corruption - use simpler approach for better performance
        if decayFactor > 0.4 { // Only apply to higher decay levels
            result = corruptCharacters(in: result, factor: decayFactor)
        }
        
        // No more complex operations for list view performance
        // Only do character corruption and simplify how we do it
        
        // Store in cache
        if textCache.count > cacheLimit {
            // Clear oldest entries if cache is too large
            textCache = [:]
        }
        
        if textCache[text] == nil {
            textCache[text] = [:]
        }
        textCache[text]?[validDecayLevel] = result
        
        return result
    }
    
    // Replace some characters with similar looking ones - simplified for performance
    private static func corruptCharacters(in text: String, factor: Double) -> String {
        // Simplified corruption - only do a subset of characters
        let corruptionMap: [Character: Character] = [
            "a": "4",
            "e": "3",
            "i": "1",
            "o": "0", 
            "s": "5"
        ]
        
        // Reduce corruption chance for better performance
        let corruptionChance = min(factor * 0.3, 0.3) // Max 30% corruption at full decay
        
        // Only process if there's a reasonable chance of corruption
        guard corruptionChance > 0.05 else { return text }
        
        var result = ""
        for char in text {
            if let replacement = corruptionMap[char.lowercased().first ?? char], 
               Double.random(in: 0...1) < corruptionChance {
                result.append(replacement)
            } else {
                result.append(char)
            }
        }
        
        return result
    }
    
    // Calculate the amount of blur to apply based on decay level - simplified
    static func blurEffect(for decayLevel: Int) -> Double {
        let validDecayLevel = max(0, min(decayLevel, 100))
        return Double(validDecayLevel) / 100.0 // Linear scaling, max 1.0
    }
    
    // Calculate the opacity for text based on decay level - simplified
    static func opacityEffect(for decayLevel: Int) -> Double {
        let validDecayLevel = max(0, min(decayLevel, 100))
        return max(1.0 - (Double(validDecayLevel) / 150.0), 0.5) // Min opacity of 0.5 at full decay
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