//
//  ExamPreparationView.swift
//  MargaSatya
//
//  Exam Preparation Screen
//

import SwiftUI

struct ExamPreparationView: View {
    @StateObject var viewModel: ExamPreparationViewModel
    @Binding var shouldStartExam: Bool

    init(
        viewModel: ExamPreparationViewModel,
        shouldStartExam: Binding<Bool>
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._shouldStartExam = shouldStartExam
    }

    var body: some View {
        ZStack {
            GlassBackground()

            VStack(spacing: 30) {
                Spacer()

                // Exam Info Card
                GlassCard {
                    VStack(spacing: 20) {
                        // Icon
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        // Title
                        Text(viewModel.examSession.examTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Divider()
                            .background(Color.white.opacity(0.3))

                        // Exam Details
                        VStack(spacing: 16) {
                            HStack {
                                Label("Duration", systemImage: "clock.fill")
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text("\(examSession.duration) minutes")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }

                            HStack {
                                Label("Exam ID", systemImage: "number.circle.fill")
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text(viewModel.examSession.examId)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }

                            if viewModel.examSession.lockMode {
                                HStack {
                                    Label("Lock Mode", systemImage: "lock.shield.fill")
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    Text("Enabled")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .font(.subheadline)

                        Divider()
                            .background(Color.white.opacity(0.3))

                        // Instructions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Important Instructions:")
                                .font(.headline)
                                .foregroundColor(.white)

                            VStack(alignment: .leading, spacing: 8) {
                                InstructionRow(text: "Your device will enter secure mode")
                                InstructionRow(text: "You cannot exit the app during exam")
                                InstructionRow(text: "Screenshots are disabled")
                                InstructionRow(text: "Notifications are blocked")
                            }
                        }
                        .padding(.vertical, 8)

                        // Start Button
                        GlassButton(
                            title: viewModel.isPreparingAssessment ? "Preparing..." : "Start Exam",
                            action: {
                                Task {
                                    await viewModel.startExam()
                                }
                            },
                            isEnabled: !viewModel.isPreparingAssessment
                        )
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .alert("Assessment Mode Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .onChange(of: viewModel.shouldStartExam) { _, shouldStart in
            if shouldStart {
                shouldStartExam = true
            }
        }
    }
}

// MARK: - Instruction Row Component
struct InstructionRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)

            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

#Preview {
    ExamPreparationView(
        examSession: ExamSession(
            examId: "EX001",
            examUrl: "https://example.com",
            examTitle: "Ujian Akhir Semester",
            duration: 60,
            lockMode: true
        ),
        shouldStartExam: .constant(false)
    )
}
