//
//  ExamServiceProtocol.swift
//  SecureExamID
//
//  Protocol for exam management operations
//

import Foundation

// MARK: - Exam Service Protocol

protocol ExamServiceProtocol {
    /// Get exam by unique exam code
    func getExam(byCode code: String) async throws -> Exam?

    /// Get exam by ID
    func getExam(byId id: String) async throws -> Exam?

    /// Create new exam
    func createExam(_ draft: ExamDraft, teacherId: String) async throws -> Exam

    /// Update existing exam
    func updateExam(_ exam: Exam) async throws

    /// Delete exam
    func deleteExam(examId: String) async throws

    /// List all exams for a teacher
    func listExams(forTeacher teacherId: String) async throws -> [Exam]

    /// List exams with filter
    func listExams(
        forTeacher teacherId: String,
        status: ExamStatusFilter
    ) async throws -> [Exam]

    /// List all questions for an exam
    func listQuestions(forExamId examId: String) async throws -> [ExamQuestion]

    /// Save questions for an exam
    func saveQuestions(_ questions: [ExamQuestion], forExamId examId: String) async throws

    /// Add single question
    func addQuestion(_ question: ExamQuestion, forExamId examId: String) async throws

    /// Update single question
    func updateQuestion(_ question: ExamQuestion, forExamId examId: String) async throws

    /// Delete question
    func deleteQuestion(questionId: String, forExamId examId: String) async throws

    /// List participants for an exam
    func listParticipants(forExamId examId: String) async throws -> [ExamParticipant]

    /// Save participants for an exam
    func saveParticipants(_ participants: [ExamParticipant], forExamId examId: String) async throws

    /// Add participant
    func addParticipant(_ participant: ExamParticipant, forExamId examId: String) async throws

    /// Remove participant
    func removeParticipant(studentId: String, forExamId examId: String) async throws

    /// Check if exam code is unique
    func isExamCodeUnique(_ code: String) async throws -> Bool
}

// MARK: - Exam Status Filter

enum ExamStatusFilter {
    case all
    case notStarted // current time < startTime
    case running // startTime <= current time <= endTime
    case finished // current time > endTime
}

// MARK: - Exam Draft (for creation)

struct ExamDraft {
    let title: String
    let description: String
    let examCode: String
    let type: ExamType
    let formUrl: String? // Only for Google Form
    let startTime: Date?
    let endTime: Date?
    let durationMinutes: Int?
}
