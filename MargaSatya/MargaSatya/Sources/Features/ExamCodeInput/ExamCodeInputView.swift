//
//  ExamCodeInputView.swift
//  MargaSatya
//
//  Exam Code Input Screen
//

import SwiftUI

struct ExamCodeInputView: View {
    @StateObject private var viewModel = ExamCodeInputViewModel()
    @Binding var examSession: ExamSession?
    @Binding var shouldPrepareExam: Bool

    var body: some View {
        ZStack {
            // Background
            GlassBackground()

            // Content
            VStack(spacing: 40) {
                Spacer()

                // Logo / Title
                VStack(spacing: 12) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 70))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.5), radius: 20)

                    Text("MargaSatya")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Secure Exam Browser")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 20)

                // Input Card
                GlassCard {
                    VStack(spacing: 20) {
                        Text("Enter Exam Code")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        GlassTextField(
                            placeholder: "EXAM CODE",
                            text: $viewModel.examCode,
                            icon: "number.circle.fill"
                        )

                        if let errorMessage = viewModel.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(errorMessage)
                                    .font(.caption)
                            }
                            .foregroundColor(.red.opacity(0.9))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.2))
                            )
                            .transition(.scale.combined(with: .opacity))
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
                .padding(.horizontal, 32)
                .sensoryFeedback(.impact, trigger: viewModel.errorMessage)

                Spacer()

                // Footer
                Text("v1.0 • iOS Secure Exam")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 20)
            }
        }
        .onChange(of: viewModel.validatedSession) { _, newSession in
            if let session = newSession {
                examSession = session
                shouldPrepareExam = true
            }
        }
    }
}

#Preview {
    ExamCodeInputView(
        examSession: .constant(nil),
        shouldPrepareExam: .constant(false)
    )
}
