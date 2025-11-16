//
//  ContentView.swift
//  MargaSatya
//
//  Main Navigation Controller
//

import SwiftUI

struct ContentView: View {
    @StateObject private var examSession = ExamSession()
    @State private var currentScreen: ExamScreen = .codeInput
    @State private var shouldPrepareExam = false
    @State private var shouldStartExam = false
    @State private var shouldCompleteExam = false
    @State private var shouldReturnHome = false

    var body: some View {
        ZStack {
            switch currentScreen {
            case .codeInput:
                ExamCodeInputView(
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
                .transition(.opacity)

            case .preparation:
                ExamPreparationView(
                    examSession: examSession,
                    shouldStartExam: $shouldStartExam
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            case .exam:
                SecureExamView(
                    examSession: examSession,
                    shouldCompleteExam: $shouldCompleteExam
                )
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
        .animation(.easeInOut(duration: 0.3), value: currentScreen)
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
