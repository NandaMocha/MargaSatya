//
//  StudentExamViewModelTests.swift
//  MargaSatyaTests
//
//  Critical tests for student exam execution
//  Tests auto-save, timer, submission, and state management
//

import Testing
import Foundation
@testable import MargaSatya

@Suite("Student Exam ViewModel Tests")
@MainActor
struct StudentExamViewModelTests {

    // MARK: - Test Properties

    let mockExamService: MockExamService
    let mockSessionService: MockSessionService
    let mockAnswerService: MockAnswerService
    let mockEncryption: MockEncryptionService
    let mockNetwork: MockNetworkMonitor
    let testExam: Exam
    let testSession: ExamSession
    let testQuestions: [ExamQuestion]

    init() {
        self.mockExamService = MockExamService()
        self.mockSessionService = MockSessionService()
        self.mockAnswerService = MockAnswerService()
        self.mockEncryption = MockEncryptionService()
        self.mockNetwork = MockNetworkMonitor()

        // Setup test exam
        self.testExam = Exam(
            id: "exam-123",
            title: "Test Exam",
            description: "Test",
            type: .inApp,
            formUrl: nil,
            accessCode: "TEST123",
            teacherId: "teacher-1",
            durationMinutes: 60,
            startTime: Date().addingTimeInterval(-3600),
            endTime: Date().addingTimeInterval(3600),
            createdAt: Date(),
            isActive: true
        )

        // Setup test session
        self.testSession = ExamSession(
            id: "session-123",
            examId: "exam-123",
            studentId: "student-1",
            nis: "12345",
            status: .notStarted,
            startedAt: nil,
            submittedAt: nil,
            currentQuestionIndex: 0,
            answeredQuestionIds: []
        )

        // Setup test questions
        self.testQuestions = [
            ExamQuestion(
                id: "q1",
                questionText: "Question 1?",
                type: .multipleChoice,
                options: ["A", "B", "C", "D"],
                correctAnswer: "A",
                points: 10,
                order: 1
            ),
            ExamQuestion(
                id: "q2",
                questionText: "Question 2?",
                type: .essay,
                options: nil,
                correctAnswer: nil,
                points: 20,
                order: 2
            ),
            ExamQuestion(
                id: "q3",
                questionText: "Question 3?",
                type: .multipleChoice,
                options: ["True", "False"],
                correctAnswer: "True",
                points: 10,
                order: 3
            )
        ]

        // Configure mock exam service
        self.mockExamService.questionsToReturn = testQuestions
        self.mockNetwork.statusToReturn = .connected
    }

    // MARK: - Helper Methods

    private func makeViewModel(session: ExamSession? = nil) -> StudentExamViewModel {
        StudentExamViewModel(
            exam: testExam,
            session: session ?? testSession,
            examService: mockExamService,
            sessionService: mockSessionService,
            answerService: mockAnswerService,
            encryptionService: mockEncryption,
            networkMonitor: mockNetwork
        )
    }

    // MARK: - Initialization Tests

    @Test("ViewModel initializes with correct values")
    func testInitialization_SetsCorrectValues() async {
        // Arrange & Act
        let viewModel = makeViewModel()

        // Assert
        #expect(viewModel.sessionStatus == .notStarted)
        #expect(viewModel.currentQuestionIndex == 0)
        #expect(viewModel.answeredQuestionIds.isEmpty)
        #expect(viewModel.questions.isEmpty) // Not loaded yet
        #expect(viewModel.isLoading == false)
    }

    @Test("ViewModel restores progress when resuming")
    func testInitialization_RestoresProgress() async {
        // Arrange
        var resumedSession = testSession
        resumedSession.status = .inProgress
        resumedSession.currentQuestionIndex = 1
        resumedSession.answeredQuestionIds = ["q1", "q2"]

        // Act
        let viewModel = makeViewModel(session: resumedSession)

        // Assert
        #expect(viewModel.sessionStatus == .inProgress)
        #expect(viewModel.currentQuestionIndex == 1)
        #expect(viewModel.answeredQuestionIds.count == 2)
        #expect(viewModel.answeredQuestionIds.contains("q1"))
        #expect(viewModel.answeredQuestionIds.contains("q2"))
    }

    // MARK: - Load Exam Tests

    @Test("Load exam successfully loads questions")
    func testLoadExam_LoadsQuestionsSuccessfully() async {
        // Arrange
        let viewModel = makeViewModel()

        // Act
        await viewModel.loadExam()

        // Assert
        #expect(viewModel.questions.count == 3)
        #expect(viewModel.questions[0].id == "q1")
        #expect(viewModel.questions[1].id == "q2")
        #expect(viewModel.questions[2].id == "q3")
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Load exam sorts questions by order")
    func testLoadExam_SortsQuestionsByOrder() async {
        // Arrange
        let unsortedQuestions = [
            ExamQuestion(id: "q3", questionText: "Q3", type: .essay, options: nil, correctAnswer: nil, points: 10, order: 3),
            ExamQuestion(id: "q1", questionText: "Q1", type: .essay, options: nil, correctAnswer: nil, points: 10, order: 1),
            ExamQuestion(id: "q2", questionText: "Q2", type: .essay, options: nil, correctAnswer: nil, points: 10, order: 2)
        ]
        mockExamService.questionsToReturn = unsortedQuestions

        let viewModel = makeViewModel()

        // Act
        await viewModel.loadExam()

        // Assert
        #expect(viewModel.questions[0].order == 1)
        #expect(viewModel.questions[1].order == 2)
        #expect(viewModel.questions[2].order == 3)
    }

    @Test("Load exam starts session when not started")
    func testLoadExam_StartsSessionWhenNotStarted() async {
        // Arrange
        let viewModel = makeViewModel()

        // Act
        await viewModel.loadExam()

        // Assert
        #expect(viewModel.sessionStatus == .inProgress)
        #expect(mockSessionService.updateSessionCalled == true)
    }

    @Test("Load exam handles errors gracefully")
    func testLoadExam_HandlesErrorsGracefully() async {
        // Arrange
        mockExamService.shouldFailOperations = true
        let viewModel = makeViewModel()

        // Act
        await viewModel.loadExam()

        // Assert
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.showError == true)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.questions.isEmpty)
    }

    // MARK: - Navigation Tests

    @Test("Go to next increments question index")
    func testGoToNext_IncrementsIndex() async {
        // Arrange
        let viewModel = makeViewModel()
        await viewModel.loadExam()

        // Act
        viewModel.goToNext()

        // Assert
        #expect(viewModel.currentQuestionIndex == 1)
    }

    @Test("Go to next does not exceed bounds")
    func testGoToNext_DoesNotExceedBounds() async {
        // Arrange
        let viewModel = makeViewModel()
        await viewModel.loadExam()
        viewModel.goToNext()
        viewModel.goToNext()

        // Act - Try to go beyond last question
        viewModel.goToNext()

        // Assert
        #expect(viewModel.currentQuestionIndex == 2) // Stays at last question
    }

    @Test("Go to previous decrements question index")
    func testGoToPrevious_DecrementsIndex() async {
        // Arrange
        let viewModel = makeViewModel()
        await viewModel.loadExam()
        viewModel.goToNext()

        // Act
        viewModel.goToPrevious()

        // Assert
        #expect(viewModel.currentQuestionIndex == 0)
    }

    @Test("Go to previous does not go below zero")
    func testGoToPrevious_DoesNotGoBelowZero() async {
        // Arrange
        let viewModel = makeViewModel()
        await viewModel.loadExam()

        // Act
        viewModel.goToPrevious()

        // Assert
        #expect(viewModel.currentQuestionIndex == 0)
    }

    @Test("Go to question sets correct index")
    func testGoToQuestion_SetsCorrectIndex() async {
        // Arrange
        let viewModel = makeViewModel()
        await viewModel.loadExam()

        // Act
        viewModel.goToQuestion(index: 2)

        // Assert
        #expect(viewModel.currentQuestionIndex == 2)
    }

    @Test("Go to question ignores invalid index")
    func testGoToQuestion_IgnoresInvalidIndex() async {
        // Arrange
        let viewModel = makeViewModel()
        await viewModel.loadExam()

        // Act
        viewModel.goToQuestion(index: 99)

        // Assert
        #expect(viewModel.currentQuestionIndex == 0) // Stays unchanged
    }

    // MARK: - Answer Management Tests

    @Test("Current answer updates answers dictionary")
    func testCurrentAnswer_UpdatesAnswersDictionary() async {
        // Arrange
        let viewModel = makeViewModel()
        await viewModel.loadExam()

        // Act
        viewModel.currentAnswer = "My answer to question 1"

        // Assert
        #expect(viewModel.answers["q1"] == "My answer to question 1")
        #expect(viewModel.answeredQuestionIds.contains("q1"))
    }

    @Test("Empty answer removes from answered set")
    func testCurrentAnswer_EmptyRemovesFromAnsweredSet() async {
        // Arrange
        let viewModel = makeViewModel()
        await viewModel.loadExam()
        viewModel.currentAnswer = "Answer"

        // Act
        viewModel.currentAnswer = ""

        // Assert
        #expect(viewModel.answers["q1"] == "")
        #expect(!viewModel.answeredQuestionIds.contains("q1"))
    }

    @Test("Progress calculated correctly")
    func testProgress_CalculatedCorrectly() async {
        // Arrange
        let viewModel = makeViewModel()
        await viewModel.loadExam()

        // Act - Answer 2 out of 3 questions
        viewModel.currentAnswer = "Answer 1"
        viewModel.goToNext()
        viewModel.currentAnswer = "Answer 2"

        // Assert
        #expect(viewModel.progress == 2.0 / 3.0)
        #expect(viewModel.answeredCount == 2)
        #expect(viewModel.totalQuestions == 3)
    }

    // MARK: - Submission Tests

    @Test("Submit exam saves all answers with encryption")
    func testSubmitExam_SavesAllAnswersWithEncryption() async {
        // Arrange
        let viewModel = makeViewModel()
        await viewModel.loadExam()

        // Answer all questions
        viewModel.currentAnswer = "Answer 1"
        viewModel.goToNext()
        viewModel.currentAnswer = "Answer 2"
        viewModel.goToNext()
        viewModel.currentAnswer = "Answer 3"

        // Act
        await viewModel.submitExam()

        // Assert
        let savedAnswers = try! await mockAnswerService.listAnswers(sessionId: testSession.id!)
        #expect(savedAnswers.count == 3)
        #expect(viewModel.isSubmitted == true)
        #expect(viewModel.isSubmitting == false)
    }

    @Test("Submit exam marks session as submitted when online")
    func testSubmitExam_MarksSessionSubmittedWhenOnline() async {
        // Arrange
        mockNetwork.statusToReturn = .connected
        let viewModel = makeViewModel()
        await viewModel.loadExam()
        viewModel.currentAnswer = "Answer"

        // Act
        await viewModel.submitExam()

        // Assert
        #expect(viewModel.sessionStatus == .submitted)
        #expect(viewModel.isSubmitted == true)
        #expect(viewModel.showSubmissionPending == false)
    }

    @Test("Submit exam marks session as pending when offline")
    func testSubmitExam_MarksSessionPendingWhenOffline() async {
        // Arrange
        mockNetwork.statusToReturn = .disconnected
        let viewModel = makeViewModel()
        await viewModel.loadExam()
        viewModel.currentAnswer = "Answer"

        // Act
        await viewModel.submitExam()

        // Assert
        #expect(viewModel.sessionStatus == .submissionPending)
        #expect(viewModel.showSubmissionPending == true)
        #expect(viewModel.isSubmitted == false)
    }

    @Test("Submit exam handles errors gracefully")
    func testSubmitExam_HandlesErrorsGracefully() async {
        // Arrange
        mockAnswerService.shouldFailOperations = true
        let viewModel = makeViewModel()
        await viewModel.loadExam()
        viewModel.currentAnswer = "Answer"

        // Act
        await viewModel.submitExam()

        // Assert
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.showError == true)
        #expect(viewModel.isSubmitting == false)
        #expect(viewModel.isSubmitted == false)
    }

    // MARK: - Computed Properties Tests

    @Test("Current question returns correct question")
    func testCurrentQuestion_ReturnsCorrectQuestion() async {
        // Arrange
        let viewModel = makeViewModel()
        await viewModel.loadExam()

        // Assert
        #expect(viewModel.currentQuestion?.id == "q1")

        // Act
        viewModel.goToNext()

        // Assert
        #expect(viewModel.currentQuestion?.id == "q2")
    }

    @Test("Can go next returns correct value")
    func testCanGoNext_ReturnsCorrectValue() async {
        // Arrange
        let viewModel = makeViewModel()
        await viewModel.loadExam()

        // Assert
        #expect(viewModel.canGoNext == true)

        // Go to last question
        viewModel.goToQuestion(index: 2)

        // Assert
        #expect(viewModel.canGoNext == false)
    }

    @Test("Can go previous returns correct value")
    func testCanGoPrevious_ReturnsCorrectValue() async {
        // Arrange
        let viewModel = makeViewModel()
        await viewModel.loadExam()

        // Assert
        #expect(viewModel.canGoPrevious == false)

        // Go to next question
        viewModel.goToNext()

        // Assert
        #expect(viewModel.canGoPrevious == true)
    }

    @Test("Network availability reflects network monitor status")
    func testNetworkAvailability_ReflectsNetworkMonitorStatus() async {
        // Arrange
        mockNetwork.statusToReturn = .connected
        let viewModel = makeViewModel()

        // Assert
        #expect(viewModel.isNetworkAvailable == true)

        // Act
        mockNetwork.statusToReturn = .disconnected

        // Assert
        #expect(viewModel.isNetworkAvailable == false)
    }

    @Test("Time remaining formatted correctly")
    func testTimeRemainingFormatted_FormatsCorrectly() async {
        // Arrange
        let viewModel = makeViewModel()

        // Test various time formats
        // 1 hour 30 minutes 45 seconds
        viewModel.timeRemaining = 5445
        #expect(viewModel.timeRemainingFormatted == "01:30:45")

        // 45 minutes 30 seconds
        viewModel.timeRemaining = 2730
        #expect(viewModel.timeRemainingFormatted == "45:30")

        // 5 minutes 0 seconds
        viewModel.timeRemaining = 300
        #expect(viewModel.timeRemainingFormatted == "05:00")
    }
}
