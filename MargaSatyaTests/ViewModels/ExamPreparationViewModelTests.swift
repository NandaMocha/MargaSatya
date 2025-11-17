//
//  ExamPreparationViewModelTests.swift
//  MargaSatyaTests
//
//  Unit tests for ExamPreparationViewModel
//

import Testing
import Foundation
@testable import MargaSatya

@MainActor
struct ExamPreparationViewModelTests {
    // MARK: - Test Properties

    let examSession: ExamSession
    let mockAssessmentService: MockAssessmentModeService
    let viewModel: ExamPreparationViewModel

    // MARK: - Initialization

    init() {
        examSession = ExamSession(
            examId: "TEST001",
            examUrl: "https://test.com/exam",
            examTitle: "Test Exam",
            duration: 60,
            lockMode: true
        )
        mockAssessmentService = MockAssessmentModeService()
        viewModel = ExamPreparationViewModel(
            examSession: examSession,
            assessmentService: mockAssessmentService
        )
    }

    // MARK: - Initialization Tests

    @Test("ViewModel initializes with correct default values")
    func testInitialState() {
        #expect(viewModel.isPreparingAssessment == false)
        #expect(viewModel.showError == false)
        #expect(viewModel.errorMessage.isEmpty)
        #expect(viewModel.shouldStartExam == false)
    }

    // MARK: - Start Exam Tests

    @Test("Starting exam with lock mode activates assessment mode")
    func testStartExamWithLockMode() async {
        mockAssessmentService.shouldStartSucceed = true

        await viewModel.startExam()

        #expect(mockAssessmentService.startCallCount == 1)
        #expect(mockAssessmentService.isInAssessmentMode == true)
        #expect(viewModel.shouldStartExam == true)
        #expect(viewModel.showError == false)
        #expect(examSession.isActive == true)
    }

    @Test("Starting exam without lock mode skips assessment mode")
    func testStartExamWithoutLockMode() async {
        // Create session without lock mode
        let unlocked Session = ExamSession(
            examId: "TEST002",
            examUrl: "https://test.com/exam2",
            examTitle: "Unlocked Exam",
            duration: 30,
            lockMode: false
        )
        let unlockedViewModel = ExamPreparationViewModel(
            examSession: unlockedSession,
            assessmentService: mockAssessmentService
        )

        await unlockedViewModel.startExam()

        #expect(mockAssessmentService.startCallCount == 0)
        #expect(unlockedViewModel.shouldStartExam == true)
        #expect(unlockedSession.isActive == true)
    }

    @Test("Starting exam handles assessment mode failure")
    func testStartExamHandlesAssessmentFailure() async {
        mockAssessmentService.shouldStartSucceed = false
        mockAssessmentService.mockError = .notSupported

        await viewModel.startExam()

        #expect(mockAssessmentService.startCallCount == 1)
        #expect(viewModel.showError == true)
        #expect(viewModel.errorMessage.isEmpty == false)
        #expect(viewModel.shouldStartExam == false)
        #expect(viewModel.isPreparingAssessment == false)
    }

    @Test("Preparing assessment state is true during exam start")
    func testPreparingAssessmentState() async {
        mockAssessmentService.shouldStartSucceed = true

        let startTask = Task {
            await viewModel.startExam()
        }

        // Brief delay to check state
        try? await Task.sleep(nanoseconds: 10_000_000)

        await startTask.value

        #expect(viewModel.isPreparingAssessment == false)
    }

    @Test("Exam session starts when assessment mode succeeds")
    func testExamSessionStarts() async {
        #expect(examSession.isActive == false)
        #expect(examSession.startTime == nil)

        await viewModel.startExam()

        #expect(examSession.isActive == true)
        #expect(examSession.startTime != nil)
    }

    @Test("Error message reflects assessment mode error")
    func testErrorMessageContent() async {
        mockAssessmentService.shouldStartSucceed = false
        mockAssessmentService.mockError = .failedToStart("Custom test error")

        await viewModel.startExam()

        #expect(viewModel.errorMessage.contains("Custom test error"))
    }

    @Test("Multiple start attempts handled correctly")
    func testMultipleStartAttempts() async {
        // First attempt - fail
        mockAssessmentService.shouldStartSucceed = false
        await viewModel.startExam()
        #expect(viewModel.showError == true)
        #expect(viewModel.shouldStartExam == false)

        // Reset mock
        mockAssessmentService.reset()

        // Second attempt - success
        mockAssessmentService.shouldStartSucceed = true
        await viewModel.startExam()
        #expect(viewModel.shouldStartExam == true)
    }
}
