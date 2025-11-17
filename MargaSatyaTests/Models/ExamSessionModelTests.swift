//
//  ExamSessionModelTests.swift
//  MargaSatyaTests
//
//  Unit tests for ExamSession model (Firestore version)
//

import Testing
import Foundation
@testable import MargaSatya

@Suite("ExamSession Model Tests")
struct ExamSessionModelTests {

    // MARK: - Initialization Tests

    @Test("Session initialization")
    func testSessionInitialization() {
        let session = ExamSession(
            examId: "exam123",
            studentId: "student123",
            nis: "12345",
            type: .inApp,
            durationMinutes: 60
        )

        #expect(session.examId == "exam123")
        #expect(session.studentId == "student123")
        #expect(session.nis == "12345")
        #expect(session.status == .notStarted)
        #expect(session.type == .inApp)
        #expect(session.durationMinutes == 60)
    }

    @Test("Session convenience init from Exam and Student")
    func testConvenienceInit() {
        let exam = Exam(
            id: "exam123",
            teacherId: "teacher123",
            title: "Test Exam",
            description: "Test",
            examCode: "TEST001",
            type: .inApp,
            durationMinutes: 90
        )

        let student = Student(
            id: "student123",
            teacherId: "teacher123",
            nis: "12345",
            name: "Ahmad"
        )

        let session = ExamSession(exam: exam, student: student)

        #expect(session.examId == "exam123")
        #expect(session.studentId == "student123")
        #expect(session.nis == "12345")
        #expect(session.type == .inApp)
        #expect(session.durationMinutes == 90)
        #expect(session.status == .notStarted)
    }

    // MARK: - Status Tests

    @Test("Session status checks")
    func testStatusChecks() {
        var session = ExamSession(
            examId: "exam123",
            studentId: "student123",
            nis: "12345",
            type: .inApp
        )

        #expect(session.isNotStarted == true)
        #expect(session.isInProgress == false)
        #expect(session.isSubmitted == false)
        #expect(session.isSubmissionPending == false)

        session.status = .inProgress
        #expect(session.isInProgress == true)
        #expect(session.isNotStarted == false)

        session.status = .submitted
        #expect(session.isSubmitted == true)

        session.status = .submissionPending
        #expect(session.isSubmissionPending == true)
    }

    // MARK: - Lifecycle Tests

    @Test("Start session")
    func testStartSession() {
        var session = ExamSession(
            examId: "exam123",
            studentId: "student123",
            nis: "12345",
            type: .inApp
        )

        #expect(session.status == .notStarted)
        #expect(session.startedAt == nil)

        session.start()

        #expect(session.status == .inProgress)
        #expect(session.startedAt != nil)
    }

    @Test("Submit session")
    func testSubmitSession() {
        var session = ExamSession(
            examId: "exam123",
            studentId: "student123",
            nis: "12345",
            type: .inApp,
            status: .inProgress
        )
        session.startedAt = Date().addingTimeInterval(-600) // Started 10 minutes ago

        #expect(session.submittedAt == nil)

        session.submit()

        #expect(session.status == .submitted)
        #expect(session.submittedAt != nil)
        #expect(session.timeSpentSeconds != nil)
    }

    @Test("Mark submission pending")
    func testMarkSubmissionPending() {
        var session = ExamSession(
            examId: "exam123",
            studentId: "student123",
            nis: "12345",
            type: .inApp,
            status: .inProgress
        )

        session.markSubmissionPending()

        #expect(session.status == .submissionPending)
    }

    // MARK: - Time Tracking Tests

    @Test("Time remaining calculation")
    func testTimeRemaining() {
        var session = ExamSession(
            examId: "exam123",
            studentId: "student123",
            nis: "12345",
            type: .inApp,
            durationMinutes: 60
        )

        // Not started yet
        #expect(session.timeRemainingSeconds == nil)

        // Start session
        session.start()

        // Should have approximately 3600 seconds (60 minutes)
        let remaining = session.timeRemainingSeconds
        #expect(remaining != nil)
        #expect(remaining! > 3590) // Allow small margin
        #expect(remaining! <= 3600)
    }

    @Test("Time expiration check")
    func testTimeExpiration() {
        var session = ExamSession(
            examId: "exam123",
            studentId: "student123",
            nis: "12345",
            type: .inApp,
            durationMinutes: 1 // 1 minute
        )

        session.start()
        session.startedAt = Date().addingTimeInterval(-120) // Started 2 minutes ago

        #expect(session.isTimeExpired == true)
    }

    @Test("No expiration for unlimited duration")
    func testNoExpirationUnlimited() {
        var session = ExamSession(
            examId: "exam123",
            studentId: "student123",
            nis: "12345",
            type: .inApp,
            durationMinutes: nil // Unlimited
        )

        session.start()
        session.startedAt = Date().addingTimeInterval(-10000) // Very old

        #expect(session.timeRemainingSeconds == nil)
        #expect(session.isTimeExpired == false)
    }

    // MARK: - Progress Tests

    @Test("Update progress")
    func testUpdateProgress() {
        var session = ExamSession(
            examId: "exam123",
            studentId: "student123",
            nis: "12345",
            type: .inApp
        )

        session.updateProgress(
            currentQuestion: 5,
            answeredIds: ["q1", "q2", "q3", "q4", "q5"]
        )

        #expect(session.currentQuestionIndex == 5)
        #expect(session.answeredQuestionIds?.count == 5)
    }

    @Test("Progress calculation")
    func testProgressCalculation() {
        var session = ExamSession(
            examId: "exam123",
            studentId: "student123",
            nis: "12345",
            type: .inApp
        )

        session.answeredQuestionIds = ["q1", "q2", "q3"]
        // Note: totalQuestions would need to be fetched from exam in real scenario
        // For now, progress will return 0 since totalQuestions is nil

        #expect(session.progress == 0)
    }

    // MARK: - Resume Tests

    @Test("Can resume in-progress session")
    func testCanResume() {
        let session = ExamSession(
            examId: "exam123",
            studentId: "student123",
            nis: "12345",
            status: .inProgress,
            type: .inApp
        )

        #expect(session.canResume == true)
    }

    @Test("Cannot resume submitted session")
    func testCannotResumeSubmitted() {
        let session = ExamSession(
            examId: "exam123",
            studentId: "student123",
            nis: "12345",
            status: .submitted,
            type: .inApp
        )

        #expect(session.canResume == false)
    }

    // MARK: - Submit Tests

    @Test("Can submit in-progress session")
    func testCanSubmit() {
        let session = ExamSession(
            examId: "exam123",
            studentId: "student123",
            nis: "12345",
            status: .inProgress,
            type: .inApp
        )

        #expect(session.canSubmit == true)
    }

    @Test("Cannot submit not-started session")
    func testCannotSubmitNotStarted() {
        let session = ExamSession(
            examId: "exam123",
            studentId: "student123",
            nis: "12345",
            status: .notStarted,
            type: .inApp
        )

        #expect(session.canSubmit == false)
    }

    // MARK: - Activity Tests

    @Test("Update activity timestamp")
    func testUpdateActivity() {
        var session = ExamSession(
            examId: "exam123",
            studentId: "student123",
            nis: "12345",
            type: .inApp
        )

        let originalActivity = session.lastActivityAt

        Thread.sleep(forTimeInterval: 0.01)

        session.updateActivity()

        #expect(session.lastActivityAt > originalActivity)
    }

    // MARK: - Sample Data Tests

    @Test("Sample session is valid")
    func testSampleSession() {
        let session = ExamSession.sample(status: .inProgress)

        #expect(session.examId == "exam123")
        #expect(session.status == .inProgress)
        #expect(session.type == .inApp)
    }
}
