//
//  SecureExamView.swift
//  MargaSatya
//
//  Secure Exam WebView Screen - OPTIMIZED VERSION
//

import SwiftUI

struct SecureExamView: View {
    @StateObject var viewModel: SecureExamViewModel
    @Binding var shouldCompleteExam: Bool

    init(
        viewModel: SecureExamViewModel,
        shouldCompleteExam: Binding<Bool>
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._shouldCompleteExam = shouldCompleteExam
    }

    var body: some View {
        ZStack {
            webViewLayer
            topBarLayer
            loadingOverlay
            errorOverlay
            adminOverlay
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onTapGesture(count: 3) {
            viewModel.handleTripleTap()
        }
        .onChange(of: viewModel.shouldCompleteExam) { _, shouldComplete in
            if shouldComplete {
                shouldCompleteExam = true
            }
        }
    }

    // MARK: - View Layers

    @ViewBuilder
    private var webViewLayer: some View {
        if let url = URL(string: viewModel.examSession.examUrl) {
            SecureWebView(
                url: url,
                isLoading: $viewModel.isLoading,
                loadError: $viewModel.loadError,
                reloadTrigger: $viewModel.reloadTrigger,
                onComplete: {
                    viewModel.completeExam()
                }
            )
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var topBarLayer: some View {
        VStack {
            HStack {
                examInfoSection
                Spacer()
                timerSection
            }
            .padding()
            .background(topBarBackground)
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)

            Spacer()
        }
    }

    @ViewBuilder
    private var examInfoSection: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.tiny) {
            Text(viewModel.examSession.examTitle)
                .font(.headline)
                .foregroundStyle(.white)

            Text("Exam ID: \(viewModel.examSession.examId)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    @ViewBuilder
    private var timerSection: some View {
        if viewModel.examSession.isActive {
            HStack(spacing: UIConstants.Spacing.small) {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .imageScale(.small)

                Text(viewModel.formatTime(seconds: viewModel.examSession.timeRemaining))
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
            }
            .foregroundStyle(viewModel.isTimerWarning ? .red : .white)
            .padding(.horizontal, UIConstants.Spacing.medium)
            .padding(.vertical, UIConstants.Spacing.small)
            .background(timerBackground)
        }
    }

    private var topBarBackground: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(UIConstants.Glass.gradientTopOpacity),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
    }

    private var timerBackground: some View {
        Capsule()
            .fill(.ultraThinMaterial)
            .overlay(
                Capsule()
                    .stroke(
                        Color.white.opacity(UIConstants.Glass.borderOpacity),
                        lineWidth: 1
                    )
            )
    }

    @ViewBuilder
    private var loadingOverlay: some View {
        if viewModel.isLoading {
            ZStack {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()

                VStack(spacing: UIConstants.Spacing.regular) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)

                    Text("Loading Exam...")
                        .foregroundStyle(.white)
                        .font(.headline)
                }
                .padding(UIConstants.Spacing.massive)
                .background(
                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
            }
        }
    }

    @ViewBuilder
    private var errorOverlay: some View {
        if let error = viewModel.loadError {
            ZStack {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()

                VStack(spacing: UIConstants.Spacing.large) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: UIConstants.IconSize.huge))
                        .foregroundStyle(.red)
                        .imageScale(.large)

                    Text("Connection Error")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text(error)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)

                    GlassButton(title: "Retry", action: {
                        viewModel.retryLoad()
                    })
                    .frame(width: 200)
                }
                .padding(UIConstants.Spacing.massive)
                .background(
                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
            }
        }
    }

    @ViewBuilder
    private var adminOverlay: some View {
        if viewModel.showAdminOverride {
            ZStack {
                Color.black.opacity(0.9)
                    .ignoresSafeArea()
                    .onTapGesture {
                        viewModel.cancelAdminOverride()
                    }

                VStack(spacing: UIConstants.Spacing.large) {
                    Text("Admin Override")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    GlassTextField(
                        placeholder: "Enter Admin PIN",
                        text: $viewModel.adminPIN,
                        icon: "lock.fill"
                    )

                    HStack(spacing: UIConstants.Spacing.medium) {
                        Button("Cancel") {
                            viewModel.cancelAdminOverride()
                        }
                        .foregroundStyle(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium, style: .continuous)
                                .fill(Color.red.opacity(0.6))
                        )

                        Button("End Exam") {
                            viewModel.forceEndExam()
                        }
                        .foregroundStyle(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium, style: .continuous)
                                .fill(Color.green.opacity(0.6))
                        )
                    }
                }
                .padding(UIConstants.Spacing.huge)
                .background(
                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.card, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .padding(UIConstants.Spacing.huge)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let examSession = ExamSession(
        examId: "EX001",
        examUrl: "https://www.google.com",
        examTitle: "Ujian Akhir",
        duration: 60,
        lockMode: true
    )
    examSession.start()

    return SecureExamView(
        viewModel: DIContainer.shared.makeSecureExamViewModel(examSession: examSession),
        shouldCompleteExam: .constant(false)
    )
}
