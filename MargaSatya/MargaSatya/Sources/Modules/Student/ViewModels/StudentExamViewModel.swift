//
//  StudentExamViewModel.swift
//  MargaSatya
//
//  ViewModel for In-App exam execution with encryption and auto-save
//

import SwiftUI
import Combine

@MainActor
final class StudentExamViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var questions: [ExamQuestion] = []
    @Published var currentQuestionIndex: Int = 0
    @Published var answers: [String: String] = [:] // questionId: plaintext answer
    @Published var answeredQuestionIds: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var isSubmitting: Bool = false
    @Published var isSubmitted: Bool = false
    @Published var showSubmissionPending: Bool = false
    @Published var timeRemaining: Int? // seconds
    @Published var sessionStatus: ExamSessionStatus = .notStarted

    // MARK: - Private Properties

    private let exam: Exam
    private var session: ExamSession
    private let examService: ExamServiceProtocol
    private let sessionService: ExamSessionServiceProtocol
    private let answerService: ExamAnswerServiceProtocol
    private let encryptionService: EncryptionServiceProtocol
    private let networkMonitor: NetworkMonitorProtocol

    private var autoSaveTimer: Timer?
    private var countdownTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var currentQuestion: ExamQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }

    var currentAnswer: String {
        get {
            guard let questionId = currentQuestion?.id else { return "" }
            return answers[questionId] ?? ""
        }
        set {
            guard let questionId = currentQuestion?.id else { return }
            answers[questionId] = newValue

            if !newValue.isEmpty {
                answeredQuestionIds.insert(questionId)
            } else {
                answeredQuestionIds.remove(questionId)
            }

            // Trigger auto-save
            scheduleAutoSave()
        }
    }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(answeredQuestionIds.count) / Double(questions.count)
    }

    var answeredCount: Int {
        answeredQuestionIds.count
    }

    var totalQuestions: Int {
        questions.count
    }

    var canGoNext: Bool {
        currentQuestionIndex < questions.count - 1
    }

    var canGoPrevious: Bool {
        currentQuestionIndex > 0
    }

    var isNetworkAvailable: Bool {
        networkMonitor.status == .connected
    }

    var timeRemainingFormatted: String {
        guard let seconds = timeRemaining else { return "" }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    // MARK: - Initialization

    init(exam: Exam, session: ExamSession, examService: ExamServiceProtocol, sessionService: ExamSessionServiceProtocol, answerService: ExamAnswerServiceProtocol, encryptionService: EncryptionServiceProtocol, networkMonitor: NetworkMonitorProtocol) {
        self.exam = exam
        self.session = session
        self.examService = examService
        self.sessionService = sessionService
        self.answerService = answerService
        self.encryptionService = encryptionService
        self.networkMonitor = networkMonitor

        self.sessionStatus = session.status
        self.currentQuestionIndex = session.currentQuestionIndex ?? 0
        self.answeredQuestionIds = Set(session.answeredQuestionIds ?? [])
    }

    // MARK: - Public Methods

    func loadExam() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load questions
            questions = try await examService.getQuestions(forExamId: exam.id ?? "")
            questions.sort { ($0.order ?? 0) < ($1.order ?? 0) }

            // Load existing answers if resuming
            if session.status == .inProgress {
                await loadExistingAnswers()
            }

            // Start session if not started
            if session.status == .notStarted {
                session.status = .inProgress
                session.startedAt = Date()
                session = try await sessionService.updateSession(session)
                sessionStatus = .inProgress
            }

            // Start countdown timer if exam has duration
            startCountdownTimer()

        } catch {
            errorMessage = "Gagal memuat soal ujian: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func goToNext() {
        guard canGoNext else { return }
        currentQuestionIndex += 1
        updateSessionProgress()
    }

    func goToPrevious() {
        guard canGoPrevious else { return }
        currentQuestionIndex -= 1
        updateSessionProgress()
    }

    func goToQuestion(index: Int) {
        guard index >= 0 && index < questions.count else { return }
        currentQuestionIndex = index
        updateSessionProgress()
    }

    func submitExam() async {
        isSubmitting = true
        errorMessage = nil

        do {
            // Save all answers with encryption
            try await saveAllAnswers()

            // Update session status
            session.status = isNetworkAvailable ? .submitted : .submissionPending
            session.submittedAt = Date()
            session = try await sessionService.updateSession(session)

            sessionStatus = session.status

            // Stop timers
            stopTimers()

            if session.status == .submissionPending {
                showSubmissionPending = true
            } else {
                isSubmitted = true
            }

        } catch {
            errorMessage = "Gagal mengirim jawaban: \(error.localizedDescription)"
            showError = true
        }

        isSubmitting = false
    }

    // MARK: - Private Methods

    private func loadExistingAnswers() async {
        guard let sessionId = session.id else { return }

        do {
            let encryptedAnswers = try await answerService.getAnswers(forSessionId: sessionId)

            for encryptedAnswer in encryptedAnswers {
                // Decrypt answer
                let plaintext = try encryptionService.decryptAnswer(encryptedAnswer)
                answers[encryptedAnswer.questionId] = plaintext
            }
        } catch {
            // Non-critical error, just log
            print("Warning: Failed to load existing answers: \(error.localizedDescription)")
        }
    }

    private func scheduleAutoSave() {
        // Invalidate existing timer
        autoSaveTimer?.invalidate()

        // Schedule new auto-save in 2 seconds
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.autoSave()
            }
        }
    }

    private func autoSave() async {
        guard let questionId = currentQuestion?.id,
              let answer = answers[questionId],
              !answer.isEmpty else { return }

        await saveAnswer(questionId: questionId, answer: answer)
    }

    private func saveAnswer(questionId: String, answer: String) async {
        guard let sessionId = session.id else { return }

        do {
            // Encrypt answer
            let encryptedAnswer = try encryptionService.encryptAnswer(
                plainText: answer,
                forQuestionId: questionId,
                sessionId: sessionId
            )

            // Save to Firestore
            try await answerService.saveAnswer(sessionId: sessionId, answer: encryptedAnswer)

        } catch {
            print("Warning: Auto-save failed: \(error.localizedDescription)")
            // Don't show error to user for auto-save failures
        }
    }

    private func saveAllAnswers() async throws {
        guard let sessionId = session.id else {
            throw ExamSessionServiceError.sessionNotFound
        }

        for (questionId, answer) in answers where !answer.isEmpty {
            let encryptedAnswer = try encryptionService.encryptAnswer(
                plainText: answer,
                forQuestionId: questionId,
                sessionId: sessionId
            )

            try await answerService.saveAnswer(sessionId: sessionId, answer: encryptedAnswer)
        }
    }

    private func updateSessionProgress() {
        Task {
            do {
                session.currentQuestionIndex = currentQuestionIndex
                session.answeredQuestionIds = Array(answeredQuestionIds)
                session = try await sessionService.updateSession(session)
            } catch {
                print("Warning: Failed to update session progress: \(error.localizedDescription)")
            }
        }
    }

    private func startCountdownTimer() {
        // Calculate time remaining
        guard let duration = exam.durationMinutes,
              let startedAt = session.startedAt else { return }

        let elapsed = Int(Date().timeIntervalSince(startedAt))
        let total = duration * 60
        timeRemaining = max(0, total - elapsed)

        // Start timer
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                if let remaining = self.timeRemaining, remaining > 0 {
                    self.timeRemaining = remaining - 1
                } else {
                    // Time's up - auto submit
                    self.stopTimers()
                    await self.submitExam()
                }
            }
        }
    }

    private func stopTimers() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    deinit {
        stopTimers()
    }
}
