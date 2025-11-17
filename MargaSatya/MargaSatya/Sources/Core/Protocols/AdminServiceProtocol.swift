//
//  AdminServiceProtocol.swift
//  SecureExamID
//
//  Protocol for admin operations and statistics
//

import Foundation

// MARK: - Admin Service Protocol

protocol AdminServiceProtocol {
    /// Get overall system summary
    func getSummary() async throws -> AdminSummary

    /// Get recent exams
    func getRecentExams(limit: Int) async throws -> [Exam]

    /// Get recent exam sessions
    func getRecentSessions(limit: Int) async throws -> [ExamSession]

    /// Get activity for specific date range
    func getActivity(
        from startDate: Date,
        to endDate: Date
    ) async throws -> ActivitySummary

    /// Get activity for today
    func getTodayActivity() async throws -> ActivitySummary

    /// Initialize Firestore collections (one-time setup)
    func initializeFirestore() async throws

    /// Get app configuration
    func getAppConfig() async throws -> AppConfig

    /// Update app configuration
    func updateAppConfig(_ config: AppConfig) async throws

    /// Get all teachers
    func listTeachers() async throws -> [User]

    /// Get all students (across all teachers)
    func listAllStudents() async throws -> [Student]

    /// Get system health status
    func getSystemHealth() async throws -> SystemHealth
}

// MARK: - Admin Summary

struct AdminSummary: Codable {
    let totalTeachers: Int
    let totalStudents: Int
    let totalExams: Int
    let runningExams: Int
    let finishedExams: Int
    let sessionsToday: Int
    let lastUpdated: Date

    init(
        totalTeachers: Int = 0,
        totalStudents: Int = 0,
        totalExams: Int = 0,
        runningExams: Int = 0,
        finishedExams: Int = 0,
        sessionsToday: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.totalTeachers = totalTeachers
        self.totalStudents = totalStudents
        self.totalExams = totalExams
        self.runningExams = runningExams
        self.finishedExams = finishedExams
        self.sessionsToday = sessionsToday
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Activity Summary

struct ActivitySummary: Codable {
    let sessionsStarted: Int
    let sessionsCompleted: Int
    let uniqueStudents: Set<String>
    let examsAccessed: Set<String>
    let averageCompletionTime: TimeInterval?

    var participationRate: Double {
        guard sessionsStarted > 0 else { return 0 }
        return Double(sessionsCompleted) / Double(sessionsStarted)
    }
}

// MARK: - System Health

struct SystemHealth: Codable {
    let firestoreConnected: Bool
    let storageUsage: StorageUsage
    let errorCount: Int
    let lastError: String?
    let timestamp: Date

    var status: HealthStatus {
        if !firestoreConnected {
            return .critical
        } else if errorCount > 10 {
            return .warning
        } else {
            return .healthy
        }
    }
}

enum HealthStatus: String, Codable {
    case healthy = "Sehat"
    case warning = "Peringatan"
    case critical = "Kritis"
}

struct StorageUsage: Codable {
    let documentsCount: Int
    let estimatedSizeMB: Double
    let quotaLimitMB: Double

    var usagePercentage: Double {
        guard quotaLimitMB > 0 else { return 0 }
        return (estimatedSizeMB / quotaLimitMB) * 100
    }
}
