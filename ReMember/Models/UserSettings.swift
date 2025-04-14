import Foundation
import Combine

// Enum to represent time unit options for decay calculation
enum DecayTimeUnit: String, CaseIterable, Identifiable {
    case minutes = "MINUTES"
    case hours = "HOURS"
    case days = "DAYS"
    
    var id: String { self.rawValue }
    
    // Multiplier to convert to minutes, which is the base unit for decay calculations
    var minuteMultiplier: Double {
        switch self {
        case .days: return 24 * 60 // 1440 minutes in a day
        case .hours: return 60 // 60 minutes in an hour
        case .minutes: return 1 // 1 minute in a minute
        }
    }
}

// Singleton class to manage user settings
class UserSettings: ObservableObject {
    // Shared instance for easy access throughout the app
    static let shared = UserSettings()
    
    // Published properties will notify observers when changed
    @Published var decayTimeUnit: DecayTimeUnit {
        didSet {
            // Save to UserDefaults when changed
            UserDefaults.standard.set(decayTimeUnit.rawValue, forKey: Keys.decayTimeUnit.rawValue)
        }
    }
    
    // Keys for UserDefaults storage
    private enum Keys: String {
        case decayTimeUnit = "decayTimeUnit"
    }
    
    // Private initializer for singleton
    private init() {
        // Load decay time unit from UserDefaults, default to days
        let storedValue = UserDefaults.standard.string(forKey: Keys.decayTimeUnit.rawValue)
        self.decayTimeUnit = DecayTimeUnit(rawValue: storedValue ?? "") ?? .days
    }
} 