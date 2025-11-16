//
//  ExamCodeInputView.swift
//  MargaSatya
//
//  Exam Code Input Screen
//

import SwiftUI

struct ExamCodeInputView: View {
    @StateObject var viewModel: ExamCodeInputViewModel
    @Binding var examSession: ExamSession?
    @Binding var shouldPrepareExam: Bool

    init(
        viewModel: ExamCodeInputViewModel,
        examSession: Binding<ExamSession?>,
        shouldPrepareExam: Binding<Bool>
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._examSession = examSession
        self._shouldPrepareExam = shouldPrepareExam
    }

    var body: some View {
        ZStack {
            // Background
            GlassBackground()

            // Content
            VStack(spacing: UIConstants.Spacing.massive) {
                Spacer()

                // Logo / Title
                VStack(spacing: UIConstants.Spacing.medium) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: UIConstants.IconSize.massive))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.5), radius: UIConstants.Shadow.radius)
                        .symbolRenderingMode(.hierarchical)

                    Text(AppConfiguration.Info.name)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(AppConfiguration.Info.tagline)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.bottom, UIConstants.Spacing.large)

                // Input Card
                GlassCard {
                    VStack(spacing: UIConstants.Spacing.large) {
                        Text("Enter Exam Code")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        GlassTextField(
                            placeholder: "EXAM CODE",
                            text: $viewModel.examCode,
                            icon: "number.circle.fill"
                        )

                        if let errorMessage = viewModel.errorMessage {
                            errorMessageView(errorMessage)
                        }

                        GlassButton(
                            title: viewModel.isLoading ? "Validating..." : "Start Exam",
                            action: {
                                Task {
                                    await viewModel.validateCode()
                                }
                            },
                            isEnabled: !viewModel.examCode.isEmpty && !viewModel.isLoading
                        )
                    }
                }
                .padding(.horizontal, UIConstants.Spacing.huge)
                .sensoryFeedback(.impact, trigger: viewModel.errorMessage)

                Spacer()

                // Footer
                Text("v\(AppConfiguration.Info.version) • iOS Secure Exam")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, UIConstants.Spacing.large)
            }
        }
        .onChange(of: viewModel.validatedSession) { _, newSession in
            if let session = newSession {
                examSession = session
                shouldPrepareExam = true
            }
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func errorMessageView(_ message: String) -> some View {
        HStack(spacing: UIConstants.Spacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .imageScale(.small)
            Text(message)
                .font(.caption)
        }
        .foregroundStyle(.red.opacity(0.9))
        .padding(.horizontal, UIConstants.Spacing.medium)
        .padding(.vertical, UIConstants.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small, style: .continuous)
                .fill(Color.red.opacity(0.2))
        )
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Preview

#Preview {
    ExamCodeInputView(
        viewModel: DIContainer.shared.makeExamCodeInputViewModel(),
        examSession: .constant(nil),
        shouldPrepareExam: .constant(false)
    )
}
