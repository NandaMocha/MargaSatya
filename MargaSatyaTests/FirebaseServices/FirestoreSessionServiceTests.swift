//
//  FirestoreSessionServiceTests.swift
//  MargaSatyaTests
//
//  Critical tests for exam session lifecycle management
//  Tests session creation, state transitions, statistics, and error handling
//

import Testing
import Foundation
@testable import MargaSatya

@Suite("Firestore Session Service Tests")
struct FirestoreSessionServiceTests {

    // MARK: - Test Properties

    let mockService: MockSessionService
    let testExam: Exam
    let testStudent: Student

    init() {
        self.mockService = MockSessionService()

        // Create test exam
        self.testExam = Exam(
            id: "exam-123",
            teacherId: "teacher-1",
            title: "Test Exam",
            description: "Test Description",
            type: .inApp,
            durationMinutes: 60,
            startTime: Date(),
            endTime: Date().addingTimeInterval(7200),
            status: .active
        )

        // Create test student
        self.testStudent = Student(
            id: "student-456",
            nis: "12345",
            name: "Test Student",
            email: "student@test.com"
        )
    }

    // MARK: - Create or Resume Session Tests

    @Test("Create new session successfully")
    func testCreateSession_Success() async throws {
        // Act
        let session = try await mockService.createOrResumeSession(
            exam: testExam,
            student: testStudent
        )

        // Assert
        #expect(session.id != nil)
        #expect(session.examId == testExam.id)
        #expect(session.studentId == testStudent.id)
        #expect(session.nis == testStudent.nis)
        #expect(session.status == .notStarted)
        #expect(session.type == testExam.type)
        #expect(session.durationMinutes == testExam.durationMinutes)
    }

    @Test("Create session with invalid exam ID throws error")
    func testCreateSession_InvalidExamId() async {
        // Arrange
        var invalidExam = testExam
        invalidExam.id = nil

        // Act & Assert
        await #expect(throws: SessionServiceError.self) {
            try await mockService.createOrResumeSession(
                exam: invalidExam,
                student: testStudent
            )
        }
    }

    @Test("Create session with invalid student ID throws error")
    func testCreateSession_InvalidStudentId() async {
        // Arrange
        var invalidStudent = testStudent
        invalidStudent.id = nil

        // Act & Assert
        await #expect(throws: SessionServiceError.self) {
            try await mockService.createOrResumeSession(
                exam: testExam,
                student: invalidStudent
            )
        }
    }

    @Test("Resume existing in-progress session")
    func testResumeSession_InProgress() async throws {
        // Arrange
        let firstSession = try await mockService.createOrResumeSession(
            exam: testExam,
            student: testStudent
        )

        // Update to in-progress
        try await mockService.updateSessionStatus(
            sessionId: firstSession.id!,
            status: .inProgress
        )

        // Act - Try to create again
        let resumedSession = try await mockService.createOrResumeSession(
            exam: testExam,
            student: testStudent
        )

        // Assert
        #expect(resumedSession.id == firstSession.id)
        #expect(resumedSession.status == .inProgress)
    }

    @Test("Resume session with SUBMISSION_PENDING status")
    func testResumeSession_SubmissionPending() async throws {
        // Arrange
        let session = try await mockService.createOrResumeSession(
            exam: testExam,
            student: testStudent
        )

        try await mockService.updateSessionStatus(
            sessionId: session.id!,
            status: .submissionPending
        )

        // Act - Should be able to resume SUBMISSION_PENDING
        let resumed = try await mockService.createOrResumeSession(
            exam: testExam,
            student: testStudent
        )

        // Assert
        #expect(resumed.id == session.id)
        #expect(resumed.status == .submissionPending)
    }

    @Test("Cannot resume submitted session")
    func testResumeSession_AlreadySubmitted() async throws {
        // Arrange
        let session = try await mockService.createOrResumeSession(
            exam: testExam,
            student: testStudent
        )

        try await mockService.submitSession(
            sessionId: session.id!,
            submittedAt: Date()
        )

        // Act & Assert
        await #expect(throws: SessionServiceError.sessionAlreadySubmitted) {
            try await mockService.createOrResumeSession(
                exam: testExam,
                student: testStudent
            )
        }
    }

    // MARK: - Get Session Tests

    @Test("Get session by ID returns correct session")
    func testGetSession_ById() async throws {
        // Arrange
        let created = try await mockService.createOrResumeSession(
            exam: testExam,
            student: testStudent
        )

        // Act
        let retrieved = try await mockService.getSession(sessionId: created.id!)

        // Assert
        #expect(retrieved != nil)
        #expect(retrieved?.id == created.id)
        #expect(retrieved?.examId == created.examId)
        #expect(retrieved?.studentId == created.studentId)
    }

    @Test("Get session by ID returns nil for non-existent session")
    func testGetSession_ByIdNotFound() async throws {
        // Act
        let session = try await mockService.getSession(sessionId: "non-existent")

        // Assert
        #expect(session == nil)
    }

    @Test("Get session by exam and student IDs")
    func testGetSession_ByExamAndStudent() async throws {
        // Arrange
        let created = try await mockService.createOrResumeSession(
            exam: testExam,
            student: testStudent
        )

        // Act
        let retrieved = try await mockService.getSession(
            examId: testExam.id!,
            studentId: testStudent.id!
        )

        // Assert
        #expect(retrieved != nil)
        #expect(retrieved?.id == created.id)
        #expect(retrieved?.examId == testExam.id)
        #expect(retrieved?.studentId == testStudent.id)
    }

    @Test("Get session returns nil for different exam")
    func testGetSession_DifferentExam() async throws {
        // Arrange
        _ = try await mockService.createOrResumeSession(
            exam: testExam,
            student: testStudent
        )

        // Act
        let session = try await mockService.getSession(
            examId: "different-exam",
            studentId: testStudent.id!
        )

        // Assert
        #expect(session == nil)
    }

    // MARK: - Update Status Tests

    @Test("Update session status successfully")
    func testUpdateStatus_Success() async throws {
        // Arrange
        let session = try await mockService.createOrResumeSession(
            exam: testExam,
            student: testStudent
        )

        // Act
        try await mockService.updateSessionStatus(
            sessionId: session.id!,
            status: .inProgress
        )

        // Assert
        let updated = try await mockService.getSession(sessionId: session.id!)
        #expect(updated?.status == .inProgress)
    }

    @Test("Update status to all valid states")
    func testUpdateStatus_AllStates() async throws {
        // Arrange
        let session = try await mockService.createOrResumeSession(
            exam: testExam,
            student: testStudent
        )

        // Test all state transitions
        let states: [ExamSessionStatus] = [
            .inProgress,
            .submissionPending,
            .submitted,
            .notStarted
        ]

        for status in states {
            // Act
            try await mockService.updateSessionStatus(
                sessionId: session.id!,
                status: status
            )

            // Assert
            let updated = try await mockService.getSession(sessionId: session.id!)
            #expect(updated?.status == status)
        }
    }

    @Test("Update status on non-existent session throws error")
    func testUpdateStatus_SessionNotFound() async {
        // Act & Assert
        await #expect(throws: SessionServiceError.sessionNotFound) {
            try await mockService.updateSessionStatus(
                sessionId: "non-existent",
                status: .inProgress
            )
        }
    }

    // MARK: - Update Last Activity Tests

    @Test("Update last activity updates timestamp")
    func testUpdateLastActivity_Success() async throws {
        // Arrange
        let session = try await mockService.createOrResumeSession(
            exam: testExam,
            student: testStudent
        )

        let originalTime = session.lastActivityAt

        // Wait a bit to ensure timestamp difference
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Act
        try await mockService.updateLastActivity(sessionId: session.id!)

        // Assert
        let updated = try await mockService.getSession(sessionId: session.id!)
        #expect(updated?.lastActivityAt > originalTime)
    }

    @Test("Update last activity on non-existent session throws error")
    func testUpdateLastActivity_SessionNotFound() async {
        // Act & Assert
        await #expect(throws: SessionServiceError.sessionNotFound) {
            try await mockService.updateLastActivity(sessionId: "non-existent")
        }
    }

    // MARK: - Submit Session Tests

    @Test("Submit session updates status and timestamp")
    func testSubmitSession_Success() async throws {
        // Arrange
        let session = try await mockService.createOrResumeSession(
            exam: testExam,
            student: testStudent
        )
        let submissionTime = Date()

        // Act
        try await mockService.submitSession(
            sessionId: session.id!,
            submittedAt: submissionTime
        )

        // Assert
        let updated = try await mockService.getSession(sessionId: session.id!)
        #expect(updated?.status == .submitted)
        #expect(updated?.submittedAt != nil)
    }

    @Test("Submit session on non-existent session throws error")
    func testSubmitSession_SessionNotFound() async {
        // Act & Assert
        await #expect(throws: SessionServiceError.sessionNotFound) {
            try await mockService.submitSession(
                sessionId: "non-existent",
                submittedAt: Date()
            )
        }
    }

    @Test("Submit session multiple times overwrites timestamp")
    func testSubmitSession_MultipleSubmissions() async throws {
        // Arrange
        let session = try await mockService.createOrResumeSession(
            exam: testExam,
            student: testStudent
        )

        let firstSubmission = Date()
        try await mockService.submitSession(
            sessionId: session.id!,
            submittedAt: firstSubmission
        )

        // Wait a bit
        try await Task.sleep(nanoseconds: 100_000_000)

        let secondSubmission = Date()

        // Act
        try await mockService.submitSession(
            sessionId: session.id!,
            submittedAt: secondSubmission
        )

        // Assert
        let updated = try await mockService.getSession(sessionId: session.id!)
        #expect(updated?.status == .submitted)
        // Verify second submission overwrote the timestamp
        if let submittedAt = updated?.submittedAt {
            #expect(submittedAt >= secondSubmission)
        } else {
            #expect(Bool(false), "Expected submittedAt to be set on resubmission")
        }
    }

    // MARK: - List Sessions Tests

    @Test("List sessions returns all sessions for exam")
    func testListSessions_AllForExam() async throws {
        // Arrange - Create 3 sessions for same exam
        let student1 = Student(id: "s1", nis: "11111", name: "S1", email: "s1@test.com")
        let student2 = Student(id: "s2", nis: "22222", name: "S2", email: "s2@test.com")
        let student3 = Student(id: "s3", nis: "33333", name: "S3", email: "s3@test.com")

        _ = try await mockService.createOrResumeSession(exam: testExam, student: student1)
        _ = try await mockService.createOrResumeSession(exam: testExam, student: student2)
        _ = try await mockService.createOrResumeSession(exam: testExam, student: student3)

        // Act
        let sessions = try await mockService.listSessions(forExamId: testExam.id!)

        // Assert
        #expect(sessions.count == 3)
    }

    @Test("List sessions returns empty array for exam with no sessions")
    func testListSessions_EmptyForExam() async throws {
        // Act
        let sessions = try await mockService.listSessions(forExamId: "no-sessions-exam")

        // Assert
        #expect(sessions.isEmpty)
    }

    @Test("List sessions filtered by status")
    func testListSessions_FilteredByStatus() async throws {
        // Arrange
        let s1 = Student(id: "s1", nis: "11111", name: "S1", email: "s1@test.com")
        let s2 = Student(id: "s2", nis: "22222", name: "S2", email: "s2@test.com")
        let s3 = Student(id: "s3", nis: "33333", name: "S3", email: "s3@test.com")

        let session1 = try await mockService.createOrResumeSession(exam: testExam, student: s1)
        let session2 = try await mockService.createOrResumeSession(exam: testExam, student: s2)
        let session3 = try await mockService.createOrResumeSession(exam: testExam, student: s3)

        // Update statuses
        try await mockService.updateSessionStatus(sessionId: session1.id!, status: .inProgress)
        try await mockService.updateSessionStatus(sessionId: session2.id!, status: .inProgress)
        try await mockService.submitSession(sessionId: session3.id!, submittedAt: Date())

        // Act
        let inProgressSessions = try await mockService.listSessions(
            forExamId: testExam.id!,
            status: .inProgress
        )
        let submittedSessions = try await mockService.listSessions(
            forExamId: testExam.id!,
            status: .submitted
        )

        // Assert
        #expect(inProgressSessions.count == 2)
        #expect(submittedSessions.count == 1)
    }

    @Test("List sessions only returns sessions for specific exam")
    func testListSessions_OnlySpecificExam() async throws {
        // Arrange
        let exam2 = Exam(
            id: "exam-999",
            teacherId: "teacher-1",
            title: "Other Exam",
            description: "Other",
            type: .inApp,
            durationMinutes: 30,
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            status: .active
        )

        let s1 = Student(id: "s1", nis: "11111", name: "S1", email: "s1@test.com")
        let s2 = Student(id: "s2", nis: "22222", name: "S2", email: "s2@test.com")

        _ = try await mockService.createOrResumeSession(exam: testExam, student: s1)
        _ = try await mockService.createOrResumeSession(exam: exam2, student: s2)

        // Act
        let exam1Sessions = try await mockService.listSessions(forExamId: testExam.id!)
        let exam2Sessions = try await mockService.listSessions(forExamId: exam2.id!)

        // Assert
        #expect(exam1Sessions.count == 1)
        #expect(exam2Sessions.count == 1)
    }

    // MARK: - Statistics Tests

    @Test("Get statistics returns correct counts")
    func testGetStatistics_CorrectCounts() async throws {
        // Arrange
        let s1 = Student(id: "s1", nis: "11111", name: "S1", email: "s1@test.com")
        let s2 = Student(id: "s2", nis: "22222", name: "S2", email: "s2@test.com")
        let s3 = Student(id: "s3", nis: "33333", name: "S3", email: "s3@test.com")
        let s4 = Student(id: "s4", nis: "44444", name: "S4", email: "s4@test.com")
        let s5 = Student(id: "s5", nis: "55555", name: "S5", email: "s5@test.com")

        let session1 = try await mockService.createOrResumeSession(exam: testExam, student: s1)
        let session2 = try await mockService.createOrResumeSession(exam: testExam, student: s2)
        let session3 = try await mockService.createOrResumeSession(exam: testExam, student: s3)
        let session4 = try await mockService.createOrResumeSession(exam: testExam, student: s4)
        let session5 = try await mockService.createOrResumeSession(exam: testExam, student: s5)

        // Set different statuses
        // s1: NOT_STARTED (default)
        try await mockService.updateSessionStatus(sessionId: session2.id!, status: .inProgress)
        try await mockService.updateSessionStatus(sessionId: session3.id!, status: .inProgress)
        try await mockService.submitSession(sessionId: session4.id!, submittedAt: Date())
        try await mockService.updateSessionStatus(sessionId: session5.id!, status: .submissionPending)

        // Act
        let stats = try await mockService.getSessionStatistics(forExamId: testExam.id!)

        // Assert
        #expect(stats.totalParticipants == 5)
        #expect(stats.notStartedCount == 1)
        #expect(stats.inProgressCount == 2)
        #expect(stats.submittedCount == 1)
        #expect(stats.submissionPendingCount == 1)
    }

    @Test("Get statistics calculates completion rate correctly")
    func testGetStatistics_CompletionRate() async throws {
        // Arrange
        let s1 = Student(id: "s1", nis: "11111", name: "S1", email: "s1@test.com")
        let s2 = Student(id: "s2", nis: "22222", name: "S2", email: "s2@test.com")
        let s3 = Student(id: "s3", nis: "33333", name: "S3", email: "s3@test.com")
        let s4 = Student(id: "s4", nis: "44444", name: "S4", email: "s4@test.com")

        let session1 = try await mockService.createOrResumeSession(exam: testExam, student: s1)
        let session2 = try await mockService.createOrResumeSession(exam: testExam, student: s2)
        _ = try await mockService.createOrResumeSession(exam: testExam, student: s3)
        _ = try await mockService.createOrResumeSession(exam: testExam, student: s4)

        // 2 out of 4 submitted
        try await mockService.submitSession(sessionId: session1.id!, submittedAt: Date())
        try await mockService.submitSession(sessionId: session2.id!, submittedAt: Date())

        // Act
        let stats = try await mockService.getSessionStatistics(forExamId: testExam.id!)

        // Assert
        #expect(stats.completionRate == 0.5) // 2/4 = 0.5
    }

    @Test("Get statistics returns zero for exam with no sessions")
    func testGetStatistics_NoSessions() async throws {
        // Act
        let stats = try await mockService.getSessionStatistics(forExamId: "no-sessions")

        // Assert
        #expect(stats.totalParticipants == 0)
        #expect(stats.notStartedCount == 0)
        #expect(stats.inProgressCount == 0)
        #expect(stats.submittedCount == 0)
        #expect(stats.submissionPendingCount == 0)
        #expect(stats.completionRate == 0)
    }

    // MARK: - Error Handling Tests

    @Test("Service fails when shouldFailOperations is true")
    func testServiceFailure_AllOperations() async throws {
        // Arrange
        mockService.shouldFailOperations = true

        // Act & Assert - Create
        await #expect(throws: SessionServiceError.permissionDenied) {
            try await mockService.createOrResumeSession(exam: testExam, student: testStudent)
        }

        // Act & Assert - Get by ID
        await #expect(throws: SessionServiceError.permissionDenied) {
            try await mockService.getSession(sessionId: "test")
        }

        // Act & Assert - Get by exam and student
        await #expect(throws: SessionServiceError.permissionDenied) {
            try await mockService.getSession(examId: "exam", studentId: "student")
        }

        // Act & Assert - Update status
        await #expect(throws: SessionServiceError.permissionDenied) {
            try await mockService.updateSessionStatus(sessionId: "test", status: .inProgress)
        }

        // Act & Assert - Update activity
        await #expect(throws: SessionServiceError.permissionDenied) {
            try await mockService.updateLastActivity(sessionId: "test")
        }

        // Act & Assert - Submit
        await #expect(throws: SessionServiceError.permissionDenied) {
            try await mockService.submitSession(sessionId: "test", submittedAt: Date())
        }

        // Act & Assert - List
        await #expect(throws: SessionServiceError.permissionDenied) {
            try await mockService.listSessions(forExamId: "exam")
        }

        // Act & Assert - Statistics
        await #expect(throws: SessionServiceError.permissionDenied) {
            try await mockService.getSessionStatistics(forExamId: "exam")
        }
    }

    // MARK: - Session Lifecycle Tests

    @Test("Complete session lifecycle from creation to submission")
    func testSessionLifecycle_Complete() async throws {
        // Step 1: Create session
        let session = try await mockService.createOrResumeSession(
            exam: testExam,
            student: testStudent
        )
        #expect(session.status == .notStarted)

        // Step 2: Start session
        try await mockService.updateSessionStatus(sessionId: session.id!, status: .inProgress)
        var updated = try await mockService.getSession(sessionId: session.id!)
        #expect(updated?.status == .inProgress)

        // Step 3: Update activity (student working)
        try await mockService.updateLastActivity(sessionId: session.id!)

        // Step 4: Network issue - mark as pending
        try await mockService.updateSessionStatus(sessionId: session.id!, status: .submissionPending)
        updated = try await mockService.getSession(sessionId: session.id!)
        #expect(updated?.status == .submissionPending)

        // Step 5: Network restored - submit
        try await mockService.submitSession(sessionId: session.id!, submittedAt: Date())
        updated = try await mockService.getSession(sessionId: session.id!)
        #expect(updated?.status == .submitted)
        #expect(updated?.submittedAt != nil)
    }

    @Test("Session state transition validation")
    func testSessionLifecycle_StateTransitions() async throws {
        // Arrange
        let session = try await mockService.createOrResumeSession(
            exam: testExam,
            student: testStudent
        )

        // Test valid transitions:
        // NOT_STARTED -> IN_PROGRESS
        try await mockService.updateSessionStatus(sessionId: session.id!, status: .inProgress)
        var current = try await mockService.getSession(sessionId: session.id!)
        #expect(current?.status == .inProgress)

        // IN_PROGRESS -> SUBMISSION_PENDING (network issue)
        try await mockService.updateSessionStatus(sessionId: session.id!, status: .submissionPending)
        current = try await mockService.getSession(sessionId: session.id!)
        #expect(current?.status == .submissionPending)

        // SUBMISSION_PENDING -> SUBMITTED (network restored)
        try await mockService.submitSession(sessionId: session.id!, submittedAt: Date())
        current = try await mockService.getSession(sessionId: session.id!)
        #expect(current?.status == .submitted)
    }

    // MARK: - Reset Tests

    @Test("Reset clears all sessions")
    func testReset_ClearsAllSessions() async throws {
        // Arrange
        let s1 = Student(id: "s1", nis: "11111", name: "S1", email: "s1@test.com")
        let s2 = Student(id: "s2", nis: "22222", name: "S2", email: "s2@test.com")

        _ = try await mockService.createOrResumeSession(exam: testExam, student: s1)
        _ = try await mockService.createOrResumeSession(exam: testExam, student: s2)

        // Verify sessions exist
        var sessions = try await mockService.listSessions(forExamId: testExam.id!)
        #expect(sessions.count == 2)

        // Act
        mockService.reset()

        // Assert
        sessions = try await mockService.listSessions(forExamId: testExam.id!)
        #expect(sessions.isEmpty)
    }
}
