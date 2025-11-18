//
//  ExamAnswerServiceProtocol.swift
//  MargaSatya
//
//  Protocol for exam answer storage (encrypted)
//

import Foundation

// MARK: - Exam Answer Service Protocol

protocol ExamAnswerServiceProtocol {
    /// Save single encrypted answer
    func saveAnswer(
        sessionId: String,
        answer: EncryptedAnswer
    ) async throws

    /// Save batch of encrypted answers
    func saveAnswersBatch(
        sessionId: String,
        answers: [EncryptedAnswer]
    ) async throws

    /// Get all answers for a session
    func listAnswers(
        sessionId: String
    ) async throws -> [EncryptedAnswer]

    /// Get specific answer by question ID
    func getAnswer(
        sessionId: String,
        questionId: String
    ) async throws -> EncryptedAnswer?

    /// Delete all answers for a session (for testing/reset)
    func deleteAllAnswers(
        sessionId: String
    ) async throws

    /// Check if answer exists for question
    func hasAnswer(
        sessionId: String,
        questionId: String
    ) async throws -> Bool

    /// Get count of answered questions
    func getAnsweredCount(
        sessionId: String
    ) async throws -> Int
}
