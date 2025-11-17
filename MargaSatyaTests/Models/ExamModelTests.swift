//
//  ExamModelTests.swift
//  MargaSatyaTests
//
//  Unit tests for Exam model
//

import Testing
import Foundation
@testable import MargaSatya

@Suite("Exam Model Tests")
struct ExamModelTests {

    // MARK: - Initialization Tests

    @Test("Exam initialization for Google Form")
    func testGoogleFormExamInitialization() {
        let exam = Exam(
            teacherId: "teacher123",
            title: "Ujian Matematika",
            description: "Ujian tengah semester",
            examCode: "MTK001",
            type: .googleForm,
            formUrl: "https://forms.google.com/abc123"
        )

        #expect(exam.type == .googleForm)
        #expect(exam.formUrl == "https://forms.google.com/abc123")
        #expect(exam.isGoogleForm == true)
        #expect(exam.isInApp == false)
    }

    @Test("Exam initialization for In-App")
    func testInAppExamInitialization() {
        let exam = Exam(
            teacherId: "teacher123",
            title: "Ujian Fisika",
            description: "Ujian akhir semester",
            examCode: "FIS001",
            type: .inApp,
            durationMinutes: 90
        )

        #expect(exam.type == .inApp)
        #expect(exam.formUrl == nil)
        #expect(exam.isInApp == true)
        #expect(exam.isGoogleForm == false)
    }

    // MARK: - Status Tests

    @Test("Exam status when not scheduled")
    func testStatusNotScheduled() {
        let exam = Exam(
            teacherId: "teacher123",
            title: "Test Exam",
            description: "Test",
            examCode: "TEST001",
            type: .inApp
        )

        #expect(exam.status == .ready)
    }

    @Test("Exam status when scheduled in future")
    func testStatusScheduled() {
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now
        let endDate = futureDate.addingTimeInterval(7200) // 2 hours after start

        let exam = Exam(
            teacherId: "teacher123",
            title: "Test Exam",
            description: "Test",
            examCode: "TEST001",
            type: .inApp,
            startTime: futureDate,
            endTime: endDate
        )

        #expect(exam.status == .scheduled)
    }

    @Test("Exam status when running")
    func testStatusRunning() {
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now

        let exam = Exam(
            teacherId: "teacher123",
            title: "Test Exam",
            description: "Test",
            examCode: "TEST001",
            type: .inApp,
            startTime: pastDate,
            endTime: futureDate
        )

        #expect(exam.status == .running)
    }

    @Test("Exam status when finished")
    func testStatusFinished() {
        let pastStartDate = Date().addingTimeInterval(-7200) // 2 hours ago
        let pastEndDate = Date().addingTimeInterval(-3600) // 1 hour ago

        let exam = Exam(
            teacherId: "teacher123",
            title: "Test Exam",
            description: "Test",
            examCode: "TEST001",
            type: .inApp,
            startTime: pastStartDate,
            endTime: pastEndDate
        )

        #expect(exam.status == .finished)
    }

    @Test("Exam status when inactive")
    func testStatusInactive() {
        var exam = Exam(
            teacherId: "teacher123",
            title: "Test Exam",
            description: "Test",
            examCode: "TEST001",
            type: .inApp
        )

        exam.deactivate()
        #expect(exam.status == .inactive)
    }

    // MARK: - Validation Tests

    @Test("Valid Google Form exam")
    func testValidGoogleFormExam() {
        let exam = Exam(
            teacherId: "teacher123",
            title: "Test Exam",
            description: "Test",
            examCode: "TEST001",
            type: .googleForm,
            formUrl: "https://forms.google.com/abc123"
        )

        #expect(exam.isValid == true)
        #expect(exam.validationErrors.isEmpty == true)
    }

    @Test("Invalid Google Form exam - no URL")
    func testInvalidGoogleFormExamNoURL() {
        let exam = Exam(
            teacherId: "teacher123",
            title: "Test Exam",
            description: "Test",
            examCode: "TEST001",
            type: .googleForm,
            formUrl: nil
        )

        #expect(exam.isValid == false)
        #expect(exam.validationErrors.contains("URL Google Form harus diisi"))
    }

    @Test("Invalid exam - empty title")
    func testInvalidExamEmptyTitle() {
        let exam = Exam(
            teacherId: "teacher123",
            title: "",
            description: "Test",
            examCode: "TEST001",
            type: .inApp
        )

        #expect(exam.isValid == false)
        #expect(exam.validationErrors.contains("Judul ujian tidak boleh kosong"))
    }

    @Test("Invalid exam - empty code")
    func testInvalidExamEmptyCode() {
        let exam = Exam(
            teacherId: "teacher123",
            title: "Test Exam",
            description: "Test",
            examCode: "",
            type: .inApp
        )

        #expect(exam.isValid == false)
        #expect(exam.validationErrors.contains("Kode ujian tidak boleh kosong"))
    }

    @Test("Invalid exam - start time after end time")
    func testInvalidExamTimeRange() {
        let startTime = Date().addingTimeInterval(7200) // 2 hours from now
        let endTime = Date().addingTimeInterval(3600) // 1 hour from now

        let exam = Exam(
            teacherId: "teacher123",
            title: "Test Exam",
            description: "Test",
            examCode: "TEST001",
            type: .inApp,
            startTime: startTime,
            endTime: endTime
        )

        #expect(exam.validationErrors.contains("Waktu mulai harus sebelum waktu selesai"))
    }

    // MARK: - Access Control Tests

    @Test("Can access running exam")
    func testCanAccessRunningExam() {
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now

        let exam = Exam(
            teacherId: "teacher123",
            title: "Test Exam",
            description: "Test",
            examCode: "TEST001",
            type: .inApp,
            startTime: pastDate,
            endTime: futureDate
        )

        let (allowed, reason) = exam.canAccess()
        #expect(allowed == true)
        #expect(reason == nil)
    }

    @Test("Cannot access exam not started")
    func testCannotAccessExamNotStarted() {
        let futureStart = Date().addingTimeInterval(3600) // 1 hour from now
        let futureEnd = Date().addingTimeInterval(7200) // 2 hours from now

        let exam = Exam(
            teacherId: "teacher123",
            title: "Test Exam",
            description: "Test",
            examCode: "TEST001",
            type: .inApp,
            startTime: futureStart,
            endTime: futureEnd
        )

        let (allowed, reason) = exam.canAccess()
        #expect(allowed == false)
        #expect(reason == "Ujian belum dimulai")
    }

    @Test("Cannot access finished exam")
    func testCannotAccessFinishedExam() {
        let pastStart = Date().addingTimeInterval(-7200) // 2 hours ago
        let pastEnd = Date().addingTimeInterval(-3600) // 1 hour ago

        let exam = Exam(
            teacherId: "teacher123",
            title: "Test Exam",
            description: "Test",
            examCode: "TEST001",
            type: .inApp,
            startTime: pastStart,
            endTime: pastEnd
        )

        let (allowed, reason) = exam.canAccess()
        #expect(allowed == false)
        #expect(reason == "Ujian sudah berakhir")
    }

    @Test("Cannot access inactive exam")
    func testCannotAccessInactiveExam() {
        var exam = Exam(
            teacherId: "teacher123",
            title: "Test Exam",
            description: "Test",
            examCode: "TEST001",
            type: .inApp
        )

        exam.deactivate()

        let (allowed, reason) = exam.canAccess()
        #expect(allowed == false)
        #expect(reason == "Ujian tidak aktif")
    }

    // MARK: - Duration Display Tests

    @Test("Duration display for minutes")
    func testDurationDisplayMinutes() {
        let exam = Exam(
            teacherId: "teacher123",
            title: "Test Exam",
            description: "Test",
            examCode: "TEST001",
            type: .inApp,
            durationMinutes: 45
        )

        #expect(exam.durationDisplay == "45 menit")
    }

    @Test("Duration display for hours")
    func testDurationDisplayHours() {
        let exam = Exam(
            teacherId: "teacher123",
            title: "Test Exam",
            description: "Test",
            examCode: "TEST001",
            type: .inApp,
            durationMinutes: 120
        )

        #expect(exam.durationDisplay == "2 jam")
    }

    @Test("Duration display for hours and minutes")
    func testDurationDisplayHoursAndMinutes() {
        let exam = Exam(
            teacherId: "teacher123",
            title: "Test Exam",
            description: "Test",
            examCode: "TEST001",
            type: .inApp,
            durationMinutes: 90
        )

        #expect(exam.durationDisplay == "1 jam 30 menit")
    }

    @Test("Duration display for unlimited")
    func testDurationDisplayUnlimited() {
        let exam = Exam(
            teacherId: "teacher123",
            title: "Test Exam",
            description: "Test",
            examCode: "TEST001",
            type: .inApp,
            durationMinutes: nil
        )

        #expect(exam.durationDisplay == "Tidak dibatasi")
    }

    // MARK: - Mutation Tests

    @Test("Update metadata")
    func testUpdateMetadata() {
        var exam = Exam(
            teacherId: "teacher123",
            title: "Test Exam",
            description: "Test",
            examCode: "TEST001",
            type: .inApp
        )

        #expect(exam.totalQuestions == nil)
        #expect(exam.totalParticipants == nil)

        exam.updateMetadata(questions: 20, participants: 30)

        #expect(exam.totalQuestions == 20)
        #expect(exam.totalParticipants == 30)
    }

    @Test("Activation toggle")
    func testActivationToggle() {
        var exam = Exam(
            teacherId: "teacher123",
            title: "Test Exam",
            description: "Test",
            examCode: "TEST001",
            type: .inApp
        )

        #expect(exam.isActive == true)

        exam.deactivate()
        #expect(exam.isActive == false)

        exam.activate()
        #expect(exam.isActive == true)
    }
}
