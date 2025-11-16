//
//  SecureExamView.swift
//  MargaSatya
//
//  Secure Exam WebView Screen
//

import SwiftUI

struct SecureExamView: View {
    @ObservedObject var examSession: ExamSession
    @Binding var shouldCompleteExam: Bool
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var showAdminOverride = false
    @State private var adminPIN = ""
    @State private var tapCount = 0
    @State private var lastTapTime = Date()

    // Timer for countdown
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            // WebView
            if let url = URL(string: examSession.examUrl) {
                SecureWebView(
                    url: url,
                    isLoading: $isLoading,
                    loadError: $loadError,
                    onComplete: {
                        completeExam()
                    }
                )
                .ignoresSafeArea()
            }

            // Top Bar (Glass)
            VStack {
                HStack {
                    // Exam Title
                    VStack(alignment: .leading, spacing: 4) {
                        Text(examSession.examTitle)
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("Exam ID: \(examSession.examId)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    // Timer
                    if examSession.isActive {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.caption)

                            Text(timeString(from: examSession.timeRemaining))
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(examSession.timeRemaining < 300 ? .red : .white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding()
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.1),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)

                Spacer()
            }

            // Loading Overlay
            if isLoading {
                ZStack {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)

                        Text("Loading Exam...")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                    )
                }
            }

            // Error Overlay
            if let error = loadError {
                ZStack {
                    Color.black.opacity(0.8)
                        .ignoresSafeArea()

                    VStack(spacing: 20) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(.red)

                        Text("Connection Error")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text(error)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)

                        GlassButton(title: "Retry", action: {
                            loadError = nil
                        })
                        .frame(width: 200)
                    }
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                    )
                }
            }

            // Admin Override (Hidden)
            if showAdminOverride {
                adminOverrideSheet
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .onTapGesture(count: 3) {
            handleTripleTap()
        }
    }

    // MARK: - Admin Override Sheet
    private var adminOverrideSheet: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture {
                    showAdminOverride = false
                }

            VStack(spacing: 20) {
                Text("Admin Override")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                GlassTextField(
                    placeholder: "Enter Admin PIN",
                    text: $adminPIN,
                    icon: "lock.fill"
                )

                HStack(spacing: 12) {
                    Button("Cancel") {
                        showAdminOverride = false
                        adminPIN = ""
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.6))
                    )

                    Button("End Exam") {
                        if adminPIN == "1234" { // TODO: Get from backend
                            forceEndExam()
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.6))
                    )
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
            )
            .padding(32)
        }
    }

    // MARK: - Helper Functions
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            examSession.updateTimeRemaining()

            if examSession.isExpired {
                completeExam()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func timeString(from seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    private func handleTripleTap() {
        let now = Date()
        if now.timeIntervalSince(lastTapTime) < 2.0 {
            showAdminOverride = true
        }
        lastTapTime = now
    }

    private func completeExam() {
        stopTimer()
        examSession.end()
        shouldCompleteExam = true

        // End assessment mode
        AssessmentModeManager.shared.endAssessmentMode()
    }

    private func forceEndExam() {
        AssessmentModeManager.shared.forceEndAssessment()
        completeExam()
    }
}

#Preview {
    SecureExamView(
        examSession: ExamSession(
            examId: "EX001",
            examUrl: "https://www.google.com",
            examTitle: "Ujian Akhir",
            duration: 60,
            lockMode: true
        ),
        shouldCompleteExam: .constant(false)
    )
}
