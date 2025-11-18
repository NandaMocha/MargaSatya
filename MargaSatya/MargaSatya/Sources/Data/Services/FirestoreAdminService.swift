//
//  FirestoreAdminService.swift
//  MargaSatya
//
//  Firestore implementation for Admin operations and statistics
//

import Foundation
import FirebaseFirestore

// MARK: - Firestore Admin Service

final class FirestoreAdminService: AdminServiceProtocol {

    // MARK: - Properties

    private let db = Firestore.firestore()

    // MARK: - Summary

    func getSummary() async throws -> AdminSummary {
        async let teachersCount = countUsers(role: .teacher)
        async let studentsCount = countStudents()
        async let examsCount = countExams()
        async let runningExamsCount = countRunningExams()
        async let finishedExamsCount = countFinishedExams()
        async let todaySessionsCount = countTodaySessions()

        return try await AdminSummary(
            totalTeachers: teachersCount,
            totalStudents: studentsCount,
            totalExams: examsCount,
            runningExams: runningExamsCount,
            finishedExams: finishedExamsCount,
            sessionsToday: todaySessionsCount
        )
    }

    // MARK: - Recent Data

    func getRecentExams(limit: Int) async throws -> [Exam] {
        let snapshot = try await db.collection(AppConfiguration.Firebase.Collections.exams)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: Exam.self)
        }
    }

    func getRecentSessions(limit: Int) async throws -> [ExamSession] {
        let snapshot = try await db.collection(AppConfiguration.Firebase.Collections.examSessions)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: ExamSession.self)
        }
    }

    // MARK: - Activity

    func getActivity(from startDate: Date, to endDate: Date) async throws -> ActivitySummary {
        let snapshot = try await db.collection(AppConfiguration.Firebase.Collections.examSessions)
            .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("createdAt", isLessThanOrEqualTo: Timestamp(date: endDate))
            .getDocuments()

        let sessions = try snapshot.documents.compactMap { document in
            try document.data(as: ExamSession.self)
        }

        let started = sessions.count
        let completed = sessions.filter { $0.status == .submitted }.count
        let uniqueStudents = Set(sessions.map { $0.studentId })
        let examsAccessed = Set(sessions.map { $0.examId })

        // Calculate average completion time
        let completedSessions = sessions.filter {
            $0.status == .submitted && $0.startedAt != nil && $0.submittedAt != nil
        }

        let averageTime: TimeInterval?
        if !completedSessions.isEmpty {
            let totalTime = completedSessions.reduce(0.0) { sum, session in
                guard let started = session.startedAt,
                      let submitted = session.submittedAt else {
                    return sum
                }
                return sum + submitted.timeIntervalSince(started)
            }
            averageTime = totalTime / Double(completedSessions.count)
        } else {
            averageTime = nil
        }

        return ActivitySummary(
            sessionsStarted: started,
            sessionsCompleted: completed,
            uniqueStudents: uniqueStudents,
            examsAccessed: examsAccessed,
            averageCompletionTime: averageTime
        )
    }

    func getTodayActivity() async throws -> ActivitySummary {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return try await getActivity(from: startOfDay, to: endOfDay)
    }

    // MARK: - Firestore Initialization

    func initializeFirestore() async throws {
        // Create default app config
        let defaultConfig = AppConfig.default()

        try db.collection(AppConfiguration.Firebase.Collections.appConfigs)
            .document("default")
            .setData(from: defaultConfig, merge: true)
    }

    // MARK: - App Config

    func getAppConfig() async throws -> AppConfig {
        let document = try await db.collection(AppConfiguration.Firebase.Collections.appConfigs)
            .document("default")
            .getDocument()

        if document.exists {
            return try document.data(as: AppConfig.self)
        } else {
            // Return default if not exists
            return AppConfig.default()
        }
    }

    func updateAppConfig(_ config: AppConfig) async throws {
        try db.collection(AppConfiguration.Firebase.Collections.appConfigs)
            .document("default")
            .setData(from: config, merge: true)
    }

    // MARK: - List All

    func listTeachers() async throws -> [User] {
        let snapshot = try await db.collection(AppConfiguration.Firebase.Collections.users)
            .whereField("role", isEqualTo: UserRole.teacher.rawValue)
            .order(by: "name")
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: User.self)
        }
    }

    func listAllStudents() async throws -> [Student] {
        let snapshot = try await db.collection(AppConfiguration.Firebase.Collections.students)
            .order(by: "name")
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: Student.self)
        }
    }

    // MARK: - System Health

    func getSystemHealth() async throws -> SystemHealth {
        // Check Firestore connection
        let firestoreConnected: Bool
        do {
            _ = try await db.collection(AppConfiguration.Firebase.Collections.appConfigs)
                .limit(to: 1)
                .getDocuments()
            firestoreConnected = true
        } catch {
            firestoreConnected = false
        }

        // Estimate storage usage
        async let usersCount = countCollection(AppConfiguration.Firebase.Collections.users)
        async let studentsCount = countCollection(AppConfiguration.Firebase.Collections.students)
        async let examsCount = countCollection(AppConfiguration.Firebase.Collections.exams)
        async let sessionsCount = countCollection(AppConfiguration.Firebase.Collections.examSessions)

        let totalDocs = try await usersCount + studentsCount + examsCount + sessionsCount

        // Very rough estimate: average 2KB per document
        let estimatedSizeMB = Double(totalDocs) * 0.002

        let storage = StorageUsage(
            documentsCount: totalDocs,
            estimatedSizeMB: estimatedSizeMB,
            quotaLimitMB: 1024 // 1GB free tier
        )

        return SystemHealth(
            firestoreConnected: firestoreConnected,
            storageUsage: storage,
            errorCount: 0,
            lastError: nil,
            timestamp: Date()
        )
    }

    // MARK: - Private Helpers

    private func countUsers(role: UserRole) async throws -> Int {
        let snapshot = try await db.collection(AppConfiguration.Firebase.Collections.users)
            .whereField("role", isEqualTo: role.rawValue)
            .getDocuments()

        return snapshot.documents.count
    }

    private func countStudents() async throws -> Int {
        return try await countCollection(AppConfiguration.Firebase.Collections.students)
    }

    private func countExams() async throws -> Int {
        return try await countCollection(AppConfiguration.Firebase.Collections.exams)
    }

    private func countRunningExams() async throws -> Int {
        // Get all exams and filter locally (Firestore doesn't support complex date queries easily)
        let snapshot = try await db.collection(AppConfiguration.Firebase.Collections.exams)
            .whereField("isActive", isEqualTo: true)
            .getDocuments()

        let exams = try snapshot.documents.compactMap { document in
            try document.data(as: Exam.self)
        }

        return exams.filter { $0.status == .running }.count
    }

    private func countFinishedExams() async throws -> Int {
        let snapshot = try await db.collection(AppConfiguration.Firebase.Collections.exams)
            .getDocuments()

        let exams = try snapshot.documents.compactMap { document in
            try document.data(as: Exam.self)
        }

        return exams.filter { $0.status == .finished }.count
    }

    private func countTodaySessions() async throws -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let snapshot = try await db.collection(AppConfiguration.Firebase.Collections.examSessions)
            .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .getDocuments()

        return snapshot.documents.count
    }

    private func countCollection(_ collectionName: String) async throws -> Int {
        let snapshot = try await db.collection(collectionName).getDocuments()
        return snapshot.documents.count
    }
}

// MARK: - Mock Admin Service

final class MockAdminService: AdminServiceProtocol {

    // MARK: - Properties

    private var mockSummary = AdminSummary()
    private var mockExams: [Exam] = []
    private var mockSessions: [ExamSession] = []
    private var mockTeachers: [User] = []
    private var mockStudents: [Student] = []
    private var mockConfig = AppConfig.default()
    var shouldFailOperations = false

    // MARK: - Test Helpers

    func setMockSummary(_ summary: AdminSummary) {
        mockSummary = summary
    }

    func addMockExam(_ exam: Exam) {
        mockExams.append(exam)
    }

    func addMockSession(_ session: ExamSession) {
        mockSessions.append(session)
    }

    func reset() {
        mockSummary = AdminSummary()
        mockExams.removeAll()
        mockSessions.removeAll()
        mockTeachers.removeAll()
        mockStudents.removeAll()
        mockConfig = AppConfig.default()
    }

    // MARK: - Implementation

    func getSummary() async throws -> AdminSummary {
        if shouldFailOperations {
            throw AdminServiceError.permissionDenied
        }
        return mockSummary
    }

    func getRecentExams(limit: Int) async throws -> [Exam] {
        if shouldFailOperations {
            throw AdminServiceError.permissionDenied
        }
        return Array(mockExams.prefix(limit))
    }

    func getRecentSessions(limit: Int) async throws -> [ExamSession] {
        if shouldFailOperations {
            throw AdminServiceError.permissionDenied
        }
        return Array(mockSessions.prefix(limit))
    }

    func getActivity(from startDate: Date, to endDate: Date) async throws -> ActivitySummary {
        if shouldFailOperations {
            throw AdminServiceError.permissionDenied
        }

        let sessions = mockSessions.filter {
            $0.createdAt >= startDate && $0.createdAt <= endDate
        }

        return ActivitySummary(
            sessionsStarted: sessions.count,
            sessionsCompleted: sessions.filter { $0.status == .submitted }.count,
            uniqueStudents: Set(sessions.map { $0.studentId }),
            examsAccessed: Set(sessions.map { $0.examId }),
            averageCompletionTime: nil
        )
    }

    func getTodayActivity() async throws -> ActivitySummary {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return try await getActivity(from: startOfDay, to: endOfDay)
    }

    func initializeFirestore() async throws {
        if shouldFailOperations {
            throw AdminServiceError.permissionDenied
        }
        // Mock: do nothing
    }

    func getAppConfig() async throws -> AppConfig {
        if shouldFailOperations {
            throw AdminServiceError.permissionDenied
        }
        return mockConfig
    }

    func updateAppConfig(_ config: AppConfig) async throws {
        if shouldFailOperations {
            throw AdminServiceError.permissionDenied
        }
        mockConfig = config
    }

    func listTeachers() async throws -> [User] {
        if shouldFailOperations {
            throw AdminServiceError.permissionDenied
        }
        return mockTeachers
    }

    func listAllStudents() async throws -> [Student] {
        if shouldFailOperations {
            throw AdminServiceError.permissionDenied
        }
        return mockStudents
    }

    func getSystemHealth() async throws -> SystemHealth {
        if shouldFailOperations {
            throw AdminServiceError.permissionDenied
        }

        return SystemHealth(
            firestoreConnected: true,
            storageUsage: StorageUsage(documentsCount: 100, estimatedSizeMB: 0.2, quotaLimitMB: 1024),
            errorCount: 0,
            lastError: nil,
            timestamp: Date()
        )
    }
}

// MARK: - Admin Service Errors

enum AdminServiceError: LocalizedError {
    case permissionDenied
    case configNotFound

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Anda tidak memiliki izin admin"
        case .configNotFound:
            return "Konfigurasi tidak ditemukan"
        }
    }
}
