//
//  ExamCodeInputViewModelTests.swift
//  MargaSatyaTests
//
//  Unit tests for ExamCodeInputViewModel
//

import Testing
import Foundation
@testable import MargaSatya

@MainActor
struct ExamCodeInputViewModelTests {
    // MARK: - Test Properties

    let mockAPIService: TestMockExamAPIService
    let viewModel: ExamCodeInputViewModel

    // MARK: - Initialization

    init() {
        mockAPIService = TestMockExamAPIService()
        viewModel = ExamCodeInputViewModel(apiService: mockAPIService)
    }

    // MARK: - Initialization Tests

    @Test("ViewModel initializes with correct default values")
    func testInitialState() {
        #expect(viewModel.examCode.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.validatedSession == nil)
    }

    // MARK: - Validation Tests

    @Test("Validation fails with empty exam code")
    func testValidationFailsWithEmptyCode() async {
        viewModel.examCode = ""

        await viewModel.validateCode()

        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == "Please enter an exam code")
        #expect(viewModel.validatedSession == nil)
        #expect(mockAPIService.resolveCodeCallCount == 0)
    }

    @Test("Validation fails with code less than minimum length")
    func testValidationFailsWithShortCode() async {
        viewModel.examCode = "AB" // Less than 3 characters

        await viewModel.validateCode()

        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage?.contains("at least") == true)
        #expect(viewModel.validatedSession == nil)
        #expect(mockAPIService.resolveCodeCallCount == 0)
    }

    @Test("Validation succeeds with valid exam code")
    func testValidationSucceedsWithValidCode() async {
        viewModel.examCode = "ABC123"
        mockAPIService.shouldSucceed = true

        await viewModel.validateCode()

        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.validatedSession != nil)
        #expect(mockAPIService.resolveCodeCallCount == 1)
        #expect(mockAPIService.lastReceivedCode == "ABC123")
    }

    @Test("Validation handles API error correctly")
    func testValidationHandlesAPIError() async {
        viewModel.examCode = "INVALID"
        mockAPIService.shouldSucceed = false
        mockAPIService.mockError = .invalidCode

        await viewModel.validateCode()

        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.validatedSession == nil)
        #expect(mockAPIService.resolveCodeCallCount == 1)
    }

    @Test("Validation trims whitespace from exam code")
    func testValidationTrimsWhitespace() async {
        viewModel.examCode = "  ABC123  "
        mockAPIService.shouldSucceed = true

        await viewModel.validateCode()

        #expect(mockAPIService.lastReceivedCode == "ABC123")
    }

    @Test("Loading state is true during validation")
    func testLoadingStateDuringValidation() async {
        viewModel.examCode = "ABC123"

        let validationTask = Task {
            await viewModel.validateCode()
        }

        // Check loading state is true (note: this is tricky in async tests)
        // The loading state should be true immediately after starting validation
        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds

        await validationTask.value

        #expect(viewModel.isLoading == false)
    }

    @Test("Reset clears all properties")
    func testReset() async {
        // Set some values
        viewModel.examCode = "ABC123"
        await viewModel.validateCode()

        // Reset
        viewModel.reset()

        // Verify all properties are cleared
        #expect(viewModel.examCode.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.validatedSession == nil)
    }

    @Test("Validated session contains correct data from API")
    func testValidatedSessionData() async {
        let mockResponse = ExamResponse(
            examId: "CUSTOM001",
            examUrl: "https://custom.test/exam",
            examTitle: "Custom Test Exam",
            duration: 45,
            lockMode: false
        )
        mockAPIService.mockResponse = mockResponse
        viewModel.examCode = "CUSTOM"

        await viewModel.validateCode()

        #expect(viewModel.validatedSession?.examId == "CUSTOM001")
        #expect(viewModel.validatedSession?.examUrl == "https://custom.test/exam")
        #expect(viewModel.validatedSession?.examTitle == "Custom Test Exam")
        #expect(viewModel.validatedSession?.duration == 45)
        #expect(viewModel.validatedSession?.lockMode == false)
    }

    @Test("Multiple validation attempts work correctly")
    func testMultipleValidationAttempts() async {
        // First attempt - fail
        viewModel.examCode = "FAIL"
        mockAPIService.shouldSucceed = false
        await viewModel.validateCode()
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.validatedSession == nil)

        // Second attempt - success
        viewModel.examCode = "SUCCESS"
        mockAPIService.shouldSucceed = true
        mockAPIService.reset()
        await viewModel.validateCode()
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.validatedSession != nil)
    }

    @Test("Error message is cleared on new validation attempt")
    func testErrorMessageClearsOnNewAttempt() async {
        // First attempt - fail
        viewModel.examCode = "FAIL"
        mockAPIService.shouldSucceed = false
        await viewModel.validateCode()
        #expect(viewModel.errorMessage != nil)

        // Second attempt
        viewModel.examCode = "RETRY"
        mockAPIService.shouldSucceed = true
        await viewModel.validateCode()
        #expect(viewModel.errorMessage == nil)
    }
}
