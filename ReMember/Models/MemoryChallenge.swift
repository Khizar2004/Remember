import Foundation
import SwiftUI
import Combine

// Memory Challenge class to manage custom questions
class MemoryChallenge: ObservableObject {
    @Published var questions: [MemoryQuestion] = []
    @Published var currentIndex: Int = 0
    @Published var userAnswers: [String] = []
    @Published var isCompleted: Bool = false
    @Published var score: Int = 0
    
    private var entry: JournalEntry
    var onComplete: ((Bool) -> Void)?
    
    init(entry: JournalEntry, onComplete: ((Bool) -> Void)? = nil) {
        self.entry = entry
        self.onComplete = onComplete
        self.questions = entry.customQuestions
        self.userAnswers = Array(repeating: "", count: entry.customQuestions.count)
    }
    
    // Get current question
    var currentQuestion: MemoryQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    // Get completion progress as percentage
    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentIndex) / Double(questions.count) * 100
    }
    
    // Submit answer for current question
    func submitAnswer(_ answer: String) -> Bool {
        guard currentIndex < questions.count else { return false }
        
        userAnswers[currentIndex] = answer
        
        // Check if answer is correct (case insensitive)
        let correctAnswer = questions[currentIndex].answer
        let isCorrect = answer.lowercased() == correctAnswer.lowercased()
        
        if isCorrect {
            score += 1
        }
        
        // Move to next question or complete
        moveToNextQuestion()
        
        return isCorrect
    }
    
    // Move to next question
    func moveToNextQuestion() {
        if currentIndex < questions.count - 1 {
            currentIndex += 1
        } else {
            completeChallenge()
        }
    }
    
    // Complete the challenge
    private func completeChallenge() {
        isCompleted = true
        
        // Determine if challenge was successful (more than 50% correct)
        let success = Double(score) / Double(questions.count) >= 0.5
        
        // Notify completion handler
        onComplete?(success)
    }
    
    // Reset the challenge
    func reset() {
        currentIndex = 0
        userAnswers = Array(repeating: "", count: questions.count)
        score = 0
        isCompleted = false
    }
} 