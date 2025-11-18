//
//  GoogleFormExamView.swift
//  MargaSatya
//
//  View for Google Form exam with WebView
//  NOTE: In production, this would use AAC (Automatic Assessment Configuration)
//  for device lockdown during exam
//

import SwiftUI
import WebKit

struct GoogleFormExamView: View {

    // MARK: - Properties

    let exam: Exam
    let session: ExamSession
    @StateObject private var viewModel: GoogleFormExamViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showCompleteConfirmation = false

    // MARK: - Initialization

    init(exam: Exam, session: ExamSession, viewModel: GoogleFormExamViewModel) {
        self.exam = exam
        self.session = session
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Bar
                topBar

                // WebView
                if viewModel.hasFormUrl {
                    WebView(url: URL(string: viewModel.formUrl)!)
                } else {
                    errorView
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .alert("Kesalahan", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {
                viewModel.showError = false
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .confirmationDialog(
            "Selesai Ujian",
            isPresented: $showCompleteConfirmation
        ) {
            Button("Selesai", role: .destructive) {
                Task {
                    await viewModel.completeSession()
                }
            }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Pastikan Anda sudah mengirim jawaban di Google Form sebelum menyelesaikan ujian.")
        }
        .fullScreenCover(isPresented: $viewModel.isCompleted) {
            GoogleFormCompletedView(exam: exam)
        }
        .task {
            await viewModel.startSession()
        }
    }

    // MARK: - View Components

    private var topBar: some View {
        HStack {
            // Exam Title
            VStack(alignment: .leading, spacing: 4) {
                Text(exam.title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Google Form")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            // Complete Button
            Button {
                showCompleteConfirmation = true
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Selesai")
                    }
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.green, .teal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .disabled(viewModel.isLoading)
        }
        .padding()
        .background(.ultraThinMaterial.opacity(0.5))
    }

    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("URL Google Form tidak tersedia")
                .font(.title3)
                .foregroundColor(.white)

            Text("Silakan hubungi guru Anda")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - WebView

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView failed to load: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("WebView failed provisional navigation: \(error.localizedDescription)")
        }
    }
}

// MARK: - Google Form Completed View

struct GoogleFormCompletedView: View {
    let exam: Exam

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            GlassBackground()

            VStack(spacing: 32) {
                Spacer()

                // Success Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Message
                VStack(spacing: 12) {
                    Text("Ujian Selesai!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Pastikan Anda sudah mengirim jawaban di Google Form")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Info
                VStack(spacing: 8) {
                    Text(exam.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Google Form")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )

                Spacer()

                // Done Button
                Button {
                    dismiss()
                } label: {
                    Text("Selesai")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [.green, .teal],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .interactiveDismissDisabled()
    }
}
