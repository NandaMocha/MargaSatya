//
//  SecureExamViewModel.swift
//  MargaSatya
//
//  ViewModel for Secure Exam WebView
//

import Foundation
import Combine

@MainActor
final class SecureExamViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var loadError: String?
    @Published var showAdminOverride = false
    @Published var adminPIN = ""
    @Published var shouldCompleteExam = false

    // MARK: - Dependencies

    let examSession: ExamSession // Made public for view access
    private let assessmentService: any AssessmentModeServiceProtocol

    // MARK: - Private Properties

    private var timer: AnyCancellable?
    private var lastTapTime = Date()

    // MARK: - Initialization

    init(
        examSession: ExamSession,
        assessmentService: any AssessmentModeServiceProtocol
    ) {
        self.examSession = examSession
        self.assessmentService = assessmentService
    }

    // MARK: - Lifecycle

    func onAppear() {
        startTimer()
    }

    func onDisappear() {
        stopTimer()
    }

    // MARK: - Timer Management

    private func startTimer() {
        timer = Timer.publish(
            every: AppConfiguration.UI.timerUpdateInterval,
            on: .main,
            in: .common
        )
        .autoconnect()
        .sink { [weak self] _ in
            guard let self = self else { return }
            self.examSession.updateTimeRemaining()

            if self.examSession.isExpired {
                self.completeExam()
            }
        }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    // MARK: - Public Methods

    func handleTripleTap() {
        guard AppConfiguration.Features.adminOverrideEnabled else { return }

        let now = Date()
        if now.timeIntervalSince(lastTapTime) < AppConfiguration.Assessment.tripleTapWindow {
            showAdminOverride = true
        }
        lastTapTime = now
    }

    func completeExam() {
        stopTimer()
        examSession.end()
        shouldCompleteExam = true

        // End assessment mode
        assessmentService.endAssessmentMode()
    }

    func forceEndExam() {
        guard validateAdminPIN() else { return }

        assessmentService.forceEndAssessment()
        completeExam()
    }

    func cancelAdminOverride() {
        showAdminOverride = false
        adminPIN = ""
    }

    // MARK: - Helper Methods

    private func validateAdminPIN() -> Bool {
        return adminPIN == AppConfiguration.Assessment.defaultAdminPIN
    }

    func formatTime(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    var isTimerWarning: Bool {
        return examSession.timeRemaining < AppConfiguration.UI.timerWarningThreshold
    }
}
