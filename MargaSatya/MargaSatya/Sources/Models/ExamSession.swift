//
//  ExamSession.swift
//  MargaSatya
//
//  Secure Exam Browser - iOS
//

import Foundation

/// Represents an active exam session
class ExamSession: ObservableObject {
    @Published var examId: String
    @Published var examUrl: String
    @Published var examTitle: String
    @Published var duration: Int // in minutes
    @Published var lockMode: Bool
    @Published var startTime: Date?
    @Published var isActive: Bool = false
    @Published var timeRemaining: Int = 0 // in seconds

    init(examId: String = "", examUrl: String = "", examTitle: String = "", duration: Int = 0, lockMode: Bool = false) {
        self.examId = examId
        self.examUrl = examUrl
        self.examTitle = examTitle
        self.duration = duration
        self.lockMode = lockMode
    }

    /// Initialize from API response
    convenience init(from response: ExamResponse) {
        self.init(
            examId: response.examId,
            examUrl: response.examUrl,
            examTitle: response.examTitle,
            duration: response.duration,
            lockMode: response.lockMode
        )
    }

    /// Start the exam session
    func start() {
        startTime = Date()
        isActive = true
        timeRemaining = duration * 60 // convert to seconds
    }

    /// End the exam session
    func end() {
        isActive = false
        startTime = nil
    }

    /// Calculate remaining time
    func updateTimeRemaining() {
        guard let startTime = startTime else { return }
        let elapsed = Int(Date().timeIntervalSince(startTime))
        let totalSeconds = duration * 60
        timeRemaining = max(0, totalSeconds - elapsed)
    }

    /// Check if time has expired
    var isExpired: Bool {
        return timeRemaining <= 0 && isActive
    }
}
