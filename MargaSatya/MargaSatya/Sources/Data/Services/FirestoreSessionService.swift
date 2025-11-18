//
//  FirestoreSessionService.swift
//  MargaSatya
//
//  Firestore implementation for ExamSession management
//

import Foundation
import FirebaseFirestore

// MARK: - Firestore Session Service

final class FirestoreSessionService: ExamSessionServiceProtocol {

    // MARK: - Properties

    private let db = Firestore.firestore()
    private let collectionName = AppConfiguration.Firebase.Collections.examSessions

    // MARK: - Create or Resume Session

    func createOrResumeSession(exam: Exam, student: Student) async throws -> ExamSession {
        guard let examId = exam.id, let studentId = student.id else {
            throw SessionServiceError.invalidData
        }

        // Check if session already exists
        if let existingSession = try await getSession(examId: examId, studentId: studentId) {
            // Check if session can be resumed
            if existingSession.status == .submitted {
                throw SessionServiceError.sessionAlreadySubmitted
            }

            // Resume in-progress session
            return existingSession
        }

        // Create new session
        let newSession = ExamSession(exam: exam, student: student)

        let docRef = try db.collection(collectionName).addDocument(from: newSession)
        let document = try await docRef.getDocument()
        return try document.data(as: ExamSession.self)
    }

    // MARK: - Get Session

    func getSession(sessionId: String) async throws -> ExamSession? {
        let document = try await db.collection(collectionName)
            .document(sessionId)
            .getDocument()

        guard document.exists else {
            return nil
        }

        return try document.data(as: ExamSession.self)
    }

    func getSession(examId: String, studentId: String) async throws -> ExamSession? {
        let snapshot = try await db.collection(collectionName)
            .whereField("examId", isEqualTo: examId)
            .whereField("studentId", isEqualTo: studentId)
            .limit(to: 1)
            .getDocuments()

        guard let document = snapshot.documents.first else {
            return nil
        }

        return try document.data(as: ExamSession.self)
    }

    // MARK: - Update Session

    func updateSessionStatus(sessionId: String, status: ExamSessionStatus) async throws {
        try await db.collection(collectionName)
            .document(sessionId)
            .updateData([
                "status": status.rawValue,
                "updatedAt": FieldValue.serverTimestamp()
            ])
    }

    func updateLastActivity(sessionId: String) async throws {
        try await db.collection(collectionName)
            .document(sessionId)
            .updateData([
                "lastActivityAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ])
    }

    func submitSession(sessionId: String, submittedAt: Date) async throws {
        try await db.collection(collectionName)
            .document(sessionId)
            .updateData([
                "status": ExamSessionStatus.submitted.rawValue,
                "submittedAt": Timestamp(date: submittedAt),
                "lastActivityAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ])
    }

    // MARK: - List Sessions

    func listSessions(forExamId examId: String) async throws -> [ExamSession] {
        let snapshot = try await db.collection(collectionName)
            .whereField("examId", isEqualTo: examId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: ExamSession.self)
        }
    }

    func listSessions(forExamId examId: String, status: ExamSessionStatus) async throws -> [ExamSession] {
        let snapshot = try await db.collection(collectionName)
            .whereField("examId", isEqualTo: examId)
            .whereField("status", isEqualTo: status.rawValue)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: ExamSession.self)
        }
    }

    // MARK: - Statistics

    func getSessionStatistics(forExamId examId: String) async throws -> SessionStatistics {
        let allSessions = try await listSessions(forExamId: examId)

        let notStartedCount = allSessions.filter { $0.status == .notStarted }.count
        let inProgressCount = allSessions.filter { $0.status == .inProgress }.count
        let submittedCount = allSessions.filter { $0.status == .submitted }.count
        let submissionPendingCount = allSessions.filter { $0.status == .submissionPending }.count

        return SessionStatistics(
            totalParticipants: allSessions.count,
            notStartedCount: notStartedCount,
            inProgressCount: inProgressCount,
            submittedCount: submittedCount,
            submissionPendingCount: submissionPendingCount
        )
    }
}

// MARK: - Session Service Errors

enum SessionServiceError: LocalizedError {
    case sessionNotFound
    case sessionAlreadySubmitted
    case invalidData
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .sessionNotFound:
            return "Sesi ujian tidak ditemukan"
        case .sessionAlreadySubmitted:
            return "Ujian sudah dikumpulkan"
        case .invalidData:
            return "Data sesi tidak valid"
        case .permissionDenied:
            return "Anda tidak memiliki izin"
        }
    }
}

// MARK: - Mock Session Service

final class MockSessionService: ExamSessionServiceProtocol {

    // MARK: - Properties

    private var sessions: [ExamSession] = []
    var shouldFailOperations = false

    // MARK: - Test Helpers

    func addMockSession(_ session: ExamSession) {
        sessions.append(session)
    }

    func reset() {
        sessions.removeAll()
    }

    // MARK: - Implementation

    func createOrResumeSession(exam: Exam, student: Student) async throws -> ExamSession {
        if shouldFailOperations {
            throw SessionServiceError.permissionDenied
        }

        guard let examId = exam.id, let studentId = student.id else {
            throw SessionServiceError.invalidData
        }

        // Check existing
        if let existing = try await getSession(examId: examId, studentId: studentId) {
            if existing.status == .submitted {
                throw SessionServiceError.sessionAlreadySubmitted
            }
            return existing
        }

        // Create new
        var newSession = ExamSession(exam: exam, student: student)
        newSession.id = UUID().uuidString
        sessions.append(newSession)
        return newSession
    }

    func getSession(sessionId: String) async throws -> ExamSession? {
        if shouldFailOperations {
            throw SessionServiceError.permissionDenied
        }

        return sessions.first { $0.id == sessionId }
    }

    func getSession(examId: String, studentId: String) async throws -> ExamSession? {
        if shouldFailOperations {
            throw SessionServiceError.permissionDenied
        }

        return sessions.first { $0.examId == examId && $0.studentId == studentId }
    }

    func updateSessionStatus(sessionId: String, status: ExamSessionStatus) async throws {
        if shouldFailOperations {
            throw SessionServiceError.permissionDenied
        }

        guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else {
            throw SessionServiceError.sessionNotFound
        }

        sessions[index].status = status
        sessions[index].updatedAt = Date()
    }

    func updateLastActivity(sessionId: String) async throws {
        if shouldFailOperations {
            throw SessionServiceError.permissionDenied
        }

        guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else {
            throw SessionServiceError.sessionNotFound
        }

        sessions[index].lastActivityAt = Date()
        sessions[index].updatedAt = Date()
    }

    func submitSession(sessionId: String, submittedAt: Date) async throws {
        if shouldFailOperations {
            throw SessionServiceError.permissionDenied
        }

        guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else {
            throw SessionServiceError.sessionNotFound
        }

        sessions[index].status = .submitted
        sessions[index].submittedAt = submittedAt
        sessions[index].updatedAt = Date()
    }

    func listSessions(forExamId examId: String) async throws -> [ExamSession] {
        if shouldFailOperations {
            throw SessionServiceError.permissionDenied
        }

        return sessions.filter { $0.examId == examId }
    }

    func listSessions(forExamId examId: String, status: ExamSessionStatus) async throws -> [ExamSession] {
        if shouldFailOperations {
            throw SessionServiceError.permissionDenied
        }

        return sessions.filter { $0.examId == examId && $0.status == status }
    }

    func getSessionStatistics(forExamId examId: String) async throws -> SessionStatistics {
        if shouldFailOperations {
            throw SessionServiceError.permissionDenied
        }

        let allSessions = try await listSessions(forExamId: examId)

        let notStartedCount = allSessions.filter { $0.status == .notStarted }.count
        let inProgressCount = allSessions.filter { $0.status == .inProgress }.count
        let submittedCount = allSessions.filter { $0.status == .submitted }.count
        let submissionPendingCount = allSessions.filter { $0.status == .submissionPending }.count

        return SessionStatistics(
            totalParticipants: allSessions.count,
            notStartedCount: notStartedCount,
            inProgressCount: inProgressCount,
            submittedCount: submittedCount,
            submissionPendingCount: submissionPendingCount
        )
    }
}
