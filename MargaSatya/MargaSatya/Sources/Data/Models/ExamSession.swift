//
//  ExamSession.swift
//  MargaSatya
//
//  Model for active exam sessions (Firestore-backed)
//

import Foundation
import FirebaseFirestore

// MARK: - Exam Session Status

enum ExamSessionStatus: String, Codable {
    case notStarted = "NOT_STARTED"
    case inProgress = "IN_PROGRESS"
    case submitted = "SUBMITTED"
    case submissionPending = "SUBMISSION_PENDING" // Koneksi buruk, belum terkirim

    var displayName: String {
        switch self {
        case .notStarted:
            return "Belum Dimulai"
        case .inProgress:
            return "Sedang Dikerjakan"
        case .submitted:
            return "Sudah Dikumpulkan"
        case .submissionPending:
            return "Menunggu Pengiriman"
        }
    }

    var color: String {
        switch self {
        case .notStarted:
            return "gray"
        case .inProgress:
            return "blue"
        case .submitted:
            return "green"
        case .submissionPending:
            return "orange"
        }
    }
}

// MARK: - Exam Session Model

struct ExamSession: Codable, Identifiable {
    @DocumentID var id: String?
    let examId: String
    let studentId: String
    let nis: String // Cached for quick lookup
    var status: ExamSessionStatus
    var startedAt: Date?
    var submittedAt: Date?
    var lastActivityAt: Date
    let type: ExamType // GOOGLE_FORM or IN_APP
    let createdAt: Date
    var updatedAt: Date

    // MARK: - Session Data

    var deviceInfo: DeviceInfo? // Device yang digunakan
    var currentQuestionIndex: Int? // For IN_APP exams
    var answeredQuestionIds: [String]? // For tracking progress

    // MARK: - Time Tracking

    var durationMinutes: Int? // Cached from exam
    var timeSpentSeconds: Int? // Actual time spent

    // MARK: - Initialization

    init(
        id: String? = nil,
        examId: String,
        studentId: String,
        nis: String,
        status: ExamSessionStatus = .notStarted,
        startedAt: Date? = nil,
        submittedAt: Date? = nil,
        lastActivityAt: Date = Date(),
        type: ExamType,
        durationMinutes: Int? = nil,
        deviceInfo: DeviceInfo? = nil,
        currentQuestionIndex: Int? = nil,
        answeredQuestionIds: [String]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.examId = examId
        self.studentId = studentId
        self.nis = nis
        self.status = status
        self.startedAt = startedAt
        self.submittedAt = submittedAt
        self.lastActivityAt = lastActivityAt
        self.type = type
        self.durationMinutes = durationMinutes
        self.deviceInfo = deviceInfo
        self.currentQuestionIndex = currentQuestionIndex
        self.answeredQuestionIds = answeredQuestionIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.timeSpentSeconds = nil
    }

    // MARK: - Convenience Init

    init(exam: Exam, student: Student) {
        self.id = nil
        self.examId = exam.id ?? ""
        self.studentId = student.id ?? ""
        self.nis = student.nis
        self.status = .notStarted
        self.startedAt = nil
        self.submittedAt = nil
        self.lastActivityAt = Date()
        self.type = exam.type
        self.durationMinutes = exam.durationMinutes
        self.deviceInfo = DeviceInfo.current()
        self.currentQuestionIndex = 0
        self.answeredQuestionIds = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.timeSpentSeconds = nil
    }

    // MARK: - Computed Properties

    var isNotStarted: Bool {
        return status == .notStarted
    }

    var isInProgress: Bool {
        return status == .inProgress
    }

    var isSubmitted: Bool {
        return status == .submitted
    }

    var isSubmissionPending: Bool {
        return status == .submissionPending
    }

    var canResume: Bool {
        return status == .inProgress
    }

    var canSubmit: Bool {
        return status == .inProgress
    }

    var timeRemainingSeconds: Int? {
        guard let duration = durationMinutes,
              let startedAt = startedAt,
              status == .inProgress else {
            return nil
        }

        let elapsed = Int(Date().timeIntervalSince(startedAt))
        let total = duration * 60
        return max(0, total - elapsed)
    }

    var isTimeExpired: Bool {
        guard let remaining = timeRemainingSeconds else {
            return false
        }
        return remaining <= 0
    }

    var progress: Double {
        guard let answered = answeredQuestionIds?.count,
              let total = totalQuestions,
              total > 0 else {
            return 0
        }
        return Double(answered) / Double(total)
    }

    var totalQuestions: Int? {
        // This would be fetched from exam
        return nil
    }

    // MARK: - Methods

    mutating func start() {
        self.status = .inProgress
        self.startedAt = Date()
        self.lastActivityAt = Date()
        self.updatedAt = Date()
    }

    mutating func submit() {
        self.status = .submitted
        self.submittedAt = Date()
        self.lastActivityAt = Date()
        self.updatedAt = Date()

        // Calculate time spent
        if let startedAt = startedAt {
            self.timeSpentSeconds = Int(Date().timeIntervalSince(startedAt))
        }
    }

    mutating func markSubmissionPending() {
        self.status = .submissionPending
        self.lastActivityAt = Date()
        self.updatedAt = Date()
    }

    mutating func updateActivity() {
        self.lastActivityAt = Date()
        self.updatedAt = Date()
    }

    mutating func updateProgress(currentQuestion: Int, answeredIds: [String]) {
        self.currentQuestionIndex = currentQuestion
        self.answeredQuestionIds = answeredIds
        self.lastActivityAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Device Info

struct DeviceInfo: Codable {
    let deviceModel: String
    let systemVersion: String
    let appVersion: String

    static func current() -> DeviceInfo {
        #if os(iOS)
        let device = UIDevice.current
        return DeviceInfo(
            deviceModel: device.model,
            systemVersion: device.systemVersion,
            appVersion: AppConfiguration.Info.version
        )
        #else
        return DeviceInfo(
            deviceModel: "Unknown",
            systemVersion: "Unknown",
            appVersion: AppConfiguration.Info.version
        )
        #endif
    }
}

// MARK: - Equatable & Hashable

extension ExamSession: Equatable {
    static func == (lhs: ExamSession, rhs: ExamSession) -> Bool {
        return lhs.id == rhs.id
    }
}

extension ExamSession: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Sample Data

extension ExamSession {
    static func sample(status: ExamSessionStatus = .inProgress) -> ExamSession {
        return ExamSession(
            id: "session123",
            examId: "exam123",
            studentId: "student123",
            nis: "12345",
            status: status,
            startedAt: status == .inProgress ? Date() : nil,
            type: .inApp,
            durationMinutes: 60,
            currentQuestionIndex: 0,
            answeredQuestionIds: []
        )
    }
}
