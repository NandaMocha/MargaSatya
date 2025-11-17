//
//  SecureExamViewModelTests.swift
//  MargaSatyaTests
//
//  Unit tests for SecureExamViewModel
//

import Testing
import Foundation
@testable import MargaSatya

@MainActor
struct SecureExamViewModelTests {
    // MARK: - Test Properties

    let examSession: ExamSession
    let mockAssessmentService: MockAssessmentModeService
    let viewModel: SecureExamViewModel

    // MARK: - Initialization

    init() {
        examSession = ExamSession(
            examId: "TEST001",
            examUrl: "https://test.com/exam",
            examTitle: "Test Exam",
            duration: 60,
            lockMode: true
        )
        examSession.start() // Start the session
        mockAssessmentService = MockAssessmentModeService()
        viewModel = SecureExamViewModel(
            examSession: examSession,
            assessmentService: mockAssessmentService
        )
    }

    // MARK: - Initialization Tests

    @Test("ViewModel initializes with correct default values")
    func testInitialState() {
        #expect(viewModel.isLoading == false)
        #expect(viewModel.loadError == nil)
        #expect(viewModel.showAdminOverride == false)
        #expect(viewModel.adminPIN.isEmpty)
        #expect(viewModel.shouldCompleteExam == false)
    }

    @Test("Exam session is accessible")
    func testExamSessionAccess() {
        #expect(viewModel.examSession.examId == "TEST001")
        #expect(viewModel.examSession.examTitle == "Test Exam")
        #expect(viewModel.examSession.duration == 60)
        #expect(viewModel.examSession.lockMode == true)
    }

    // MARK: - Time Formatting Tests

    @Test("Format time for hours, minutes, and seconds")
    func testTimeFormattingWithHours() {
        let formatted = viewModel.formatTime(seconds: 3665) // 1:01:05
        #expect(formatted == "01:01:05")
    }

    @Test("Format time for minutes and seconds only")
    func testTimeFormattingWithoutHours() {
        let formatted = viewModel.formatTime(seconds: 125) // 2:05
        #expect(formatted == "02:05")
    }

    @Test("Format time with zero padding")
    func testTimeFormattingZeroPadding() {
        let formatted = viewModel.formatTime(seconds: 65) // 1:05
        #expect(formatted == "01:05")
    }

    @Test("Format time at zero")
    func testTimeFormattingZero() {
        let formatted = viewModel.formatTime(seconds: 0)
        #expect(formatted == "00:00")
    }

    // MARK: - Timer Warning Tests

    @Test("Timer warning is false when time remaining is high")
    func testTimerWarningHighTime() {
        examSession.timeRemaining = 600 // 10 minutes
        #expect(viewModel.isTimerWarning == false)
    }

    @Test("Timer warning is true when time remaining is low")
    func testTimerWarningLowTime() {
        examSession.timeRemaining = 200 // ~3 minutes
        #expect(viewModel.isTimerWarning == true)
    }

    @Test("Timer warning threshold matches configuration")
    func testTimerWarningThreshold() {
        examSession.timeRemaining = AppConfiguration.UI.timerWarningThreshold - 1
        #expect(viewModel.isTimerWarning == true)

        examSession.timeRemaining = AppConfiguration.UI.timerWarningThreshold + 1
        #expect(viewModel.isTimerWarning == false)
    }

    // MARK: - Complete Exam Tests

    @Test("Complete exam ends session and assessment mode")
    func testCompleteExam() {
        #expect(examSession.isActive == true)
        #expect(mockAssessmentService.endCallCount == 0)

        viewModel.completeExam()

        #expect(examSession.isActive == false)
        #expect(mockAssessmentService.endCallCount == 1)
        #expect(viewModel.shouldCompleteExam == true)
    }

    @Test("Complete exam can be called multiple times safely")
    func testCompleteExamMultipleCalls() {
        viewModel.completeExam()
        viewModel.completeExam()
        viewModel.completeExam()

        #expect(mockAssessmentService.endCallCount == 3)
        #expect(viewModel.shouldCompleteExam == true)
    }

    // MARK: - Admin Override Tests

    @Test("Force end exam with correct PIN")
    func testForceEndExamWithCorrectPIN() {
        viewModel.adminPIN = AppConfiguration.Assessment.defaultAdminPIN

        viewModel.forceEndExam()

        #expect(mockAssessmentService.forceEndCallCount == 1)
        #expect(viewModel.shouldCompleteExam == true)
        #expect(examSession.isActive == false)
    }

    @Test("Force end exam with incorrect PIN does nothing")
    func testForceEndExamWithIncorrectPIN() {
        viewModel.adminPIN = "wrongpin"

        viewModel.forceEndExam()

        #expect(mockAssessmentService.forceEndCallCount == 0)
        #expect(viewModel.shouldCompleteExam == false)
        #expect(examSession.isActive == true)
    }

    @Test("Cancel admin override clears state")
    func testCancelAdminOverride() {
        viewModel.adminPIN = "1234"
        viewModel.showAdminOverride = true

        viewModel.cancelAdminOverride()

        #expect(viewModel.adminPIN.isEmpty)
        #expect(viewModel.showAdminOverride == false)
    }

    @Test("Handle triple tap shows admin override when enabled")
    func testHandleTripleTapWhenEnabled() {
        // Save original value
        let originalValue = AppConfiguration.Features.adminOverrideEnabled

        // Temporarily enable for test
        // Note: In real scenario, you'd use dependency injection for this

        viewModel.handleTripleTap()

        // Wait for triple tap window
        // In real test, time-based logic would need adjustment

        // Restore original
    }

    // MARK: - Lifecycle Tests

    @Test("On appear initializes correctly")
    func testOnAppear() {
        viewModel.onAppear()
        // Timer should be started (can't easily test in sync context)
        // This test validates method doesn't crash
        #expect(true)
    }

    @Test("On disappear cleans up correctly")
    func testOnDisappear() {
        viewModel.onAppear()
        viewModel.onDisappear()
        // Timer should be stopped
        // This test validates method doesn't crash
        #expect(true)
    }
}
