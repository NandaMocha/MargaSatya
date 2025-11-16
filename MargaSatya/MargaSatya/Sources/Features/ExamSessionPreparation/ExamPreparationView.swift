//
//  ExamPreparationView.swift
//  MargaSatya
//
//  Exam Preparation Screen
//

import SwiftUI

struct ExamPreparationView: View {
    @ObservedObject var examSession: ExamSession
    @Binding var shouldStartExam: Bool
    @StateObject private var assessmentManager = AssessmentModeManager.shared
    @State private var isPreparingAssessment = false
    @State private var showError = false
    @State private var errorMessage = ""

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
                        Text(examSession.examTitle)
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
                                Text(examSession.examId)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }

                            if examSession.lockMode {
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
                            title: isPreparingAssessment ? "Preparing..." : "Start Exam",
                            action: {
                                Task {
                                    await startExam()
                                }
                            },
                            isEnabled: !isPreparingAssessment
                        )
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .alert("Assessment Mode Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func startExam() async {
        isPreparingAssessment = true

        // Start assessment mode if lockMode is enabled
        if examSession.lockMode {
            do {
                try await assessmentManager.startAssessmentMode()

                // Wait a moment for assessment mode to fully activate
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                // Start exam session
                examSession.start()

                // Navigate to exam
                shouldStartExam = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isPreparingAssessment = false
            }
        } else {
            // Start exam without assessment mode
            examSession.start()
            shouldStartExam = true
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
