//
//  GoogleFormExamViewModel.swift
//  MargaSatya
//
//  ViewModel for Google Form exam execution with WebView
//

import SwiftUI

@MainActor
final class GoogleFormExamViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var isCompleted: Bool = false
    @Published var sessionStatus: ExamSessionStatus = .notStarted

    // MARK: - Private Properties

    private let exam: Exam
    private var session: ExamSession
    private let sessionService: ExamSessionServiceProtocol

    // MARK: - Computed Properties

    var formUrl: String {
        exam.formUrl ?? ""
    }

    var hasFormUrl: Bool {
        guard let url = exam.formUrl else { return false }
        return !url.isEmpty
    }

    // MARK: - Initialization

    init(exam: Exam, session: ExamSession, sessionService: ExamSessionServiceProtocol) {
        self.exam = exam
        self.session = session
        self.sessionService = sessionService
        self.sessionStatus = session.status
    }

    // MARK: - Public Methods

    func startSession() async {
        guard session.status == .notStarted else { return }

        isLoading = true
        errorMessage = nil

        do {
            session.status = .inProgress
            session.startedAt = Date()
            session = try await sessionService.updateSession(session)
            sessionStatus = .inProgress
        } catch {
            errorMessage = "Gagal memulai sesi ujian: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func completeSession() async {
        isLoading = true
        errorMessage = nil

        do {
            session.status = .submitted
            session.submittedAt = Date()
            session = try await sessionService.updateSession(session)
            sessionStatus = .submitted
            isCompleted = true
        } catch {
            errorMessage = "Gagal menyelesaikan sesi ujian: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }
}
