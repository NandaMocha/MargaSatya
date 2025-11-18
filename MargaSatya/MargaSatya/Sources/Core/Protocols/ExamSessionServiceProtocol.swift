//
//  ExamSessionServiceProtocol.swift
//  MargaSatya
//
//  Protocol for exam session management
//

import Foundation

// MARK: - Exam Session Service Protocol

protocol ExamSessionServiceProtocol {
    /// Create new session or resume existing one
    func createOrResumeSession(
        exam: Exam,
        student: Student
    ) async throws -> ExamSession

    /// Get session by ID
    func getSession(sessionId: String) async throws -> ExamSession?

    /// Get session for specific exam and student
    func getSession(
        examId: String,
        studentId: String
    ) async throws -> ExamSession?

    /// Update session status
    func updateSessionStatus(
        sessionId: String,
        status: ExamSessionStatus
    ) async throws

    /// Update session last activity
    func updateLastActivity(
        sessionId: String
    ) async throws

    /// Mark session as submitted
    func submitSession(
        sessionId: String,
        submittedAt: Date
    ) async throws

    /// List all sessions for an exam
    func listSessions(forExamId examId: String) async throws -> [ExamSession]

    /// List sessions with status filter
    func listSessions(
        forExamId examId: String,
        status: ExamSessionStatus
    ) async throws -> [ExamSession]

    /// Get session statistics for exam
    func getSessionStatistics(
        forExamId examId: String
    ) async throws -> SessionStatistics
}

// MARK: - Session Statistics

struct SessionStatistics {
    let totalParticipants: Int
    let notStartedCount: Int
    let inProgressCount: Int
    let submittedCount: Int
    let submissionPendingCount: Int

    var completionRate: Double {
        guard totalParticipants > 0 else { return 0 }
        return Double(submittedCount) / Double(totalParticipants)
    }
}
