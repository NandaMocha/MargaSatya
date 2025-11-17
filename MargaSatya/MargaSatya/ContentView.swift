//
//  ContentView.swift
//  MargaSatya
//
//  Main Navigation Controller
//

import SwiftUI

struct ContentView: View {
    // MARK: - Properties

    @StateObject private var examSession = ExamSession()
    @State private var currentScreen: ExamScreen = .codeInput
    @State private var shouldPrepareExam = false
    @State private var shouldStartExam = false
    @State private var shouldCompleteExam = false
    @State private var shouldReturnHome = false

    // Dependency injection container
    private let container = DIContainer.shared

    // MARK: - Body

    var body: some View {
        ZStack {
            switch currentScreen {
            case .codeInput:
                codeInputView
                    .transition(.opacity)

            case .preparation:
                preparationView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

            case .exam:
                examView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

            case .completed:
                ExamCompletedView(shouldReturnHome: $shouldReturnHome)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.easeInOut(duration: AppConfiguration.UI.transitionDuration), value: currentScreen)
        .onChange(of: shouldPrepareExam) { _, shouldPrepare in
            if shouldPrepare {
                currentScreen = .preparation
                shouldPrepareExam = false
            }
        }
        .onChange(of: shouldStartExam) { _, shouldStart in
            if shouldStart {
                currentScreen = .exam
                shouldStartExam = false
            }
        }
        .onChange(of: shouldCompleteExam) { _, shouldComplete in
            if shouldComplete {
                currentScreen = .completed
                shouldCompleteExam = false
            }
        }
        .onChange(of: shouldReturnHome) { _, shouldReturn in
            if shouldReturn {
                resetToHome()
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(currentScreen == .exam)
    }

    private func resetToHome() {
        currentScreen = .codeInput
        shouldReturnHome = false

        // Reset exam session
        examSession.examId = ""
        examSession.examUrl = ""
        examSession.examTitle = ""
        examSession.duration = 0
        examSession.lockMode = false
        examSession.isActive = false
    }

    // MARK: - View Builders

    private var codeInputView: some View {
        ExamCodeInputView(
            viewModel: container.makeExamCodeInputViewModel(),
            examSession: Binding(
                get: { currentScreen == .preparation ? examSession : nil },
                set: { newSession in
                    if let session = newSession {
                        examSession.examId = session.examId
                        examSession.examUrl = session.examUrl
                        examSession.examTitle = session.examTitle
                        examSession.duration = session.duration
                        examSession.lockMode = session.lockMode
                    }
                }
            ),
            shouldPrepareExam: $shouldPrepareExam
        )
    }

    private var preparationView: some View {
        ExamPreparationView(
            viewModel: container.makeExamPreparationViewModel(examSession: examSession),
            shouldStartExam: $shouldStartExam
        )
    }

    private var examView: some View {
        SecureExamView(
            viewModel: container.makeSecureExamViewModel(examSession: examSession),
            shouldCompleteExam: $shouldCompleteExam
        )
    }
}

// MARK: - Exam Screen Enum
enum ExamScreen {
    case codeInput
    case preparation
    case exam
    case completed
}

#Preview {
    ContentView()
}
