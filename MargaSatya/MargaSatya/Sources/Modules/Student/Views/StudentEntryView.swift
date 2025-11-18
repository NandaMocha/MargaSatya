//
//  StudentEntryView.swift
//  MargaSatya
//
//  Student entry point for exam access
//

import SwiftUI

struct StudentEntryView: View {

    // MARK: - Properties

    @StateObject private var viewModel: StudentEntryViewModel
    @State private var showExam = false

    // MARK: - Initialization

    init(viewModel: StudentEntryViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection

                        // Form
                        formSection

                        // Proceed Button
                        proceedButton
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("Kesalahan", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {
                    viewModel.showError = false
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .navigationDestination(isPresented: $viewModel.isAuthenticated) {
                if let exam = viewModel.currentExam, let session = viewModel.currentSession {
                    examDestination(exam: exam, session: session)
                }
            }
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.fill.checkmark")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .teal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Portal Siswa")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("Masukkan NIS dan kode ujian Anda")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    private var formSection: some View {
        VStack(spacing: 20) {
            // NIS Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Nomor Induk Siswa (NIS)")
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack {
                    Image(systemName: "number")
                        .foregroundColor(.secondary)
                        .frame(width: 20)

                    TextField("Masukkan NIS Anda", text: $viewModel.nis)
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    viewModel.nisError != nil ? Color.red.opacity(0.5) : Color.clear,
                                    lineWidth: 1
                                )
                        )
                )

                if let error = viewModel.nisError {
                    errorLabel(error)
                }
            }

            // Access Code Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Kode Akses Ujian")
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)

                    TextField("Masukkan kode akses", text: $viewModel.accessCode)
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    viewModel.accessCodeError != nil ? Color.red.opacity(0.5) : Color.clear,
                                    lineWidth: 1
                                )
                        )
                )

                if let error = viewModel.accessCodeError {
                    errorLabel(error)
                }
            }

            // Info Card
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Informasi")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Kode akses ujian diberikan oleh guru Anda. Pastikan Anda memasukkan kode dengan benar.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.blue.opacity(0.1))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    private var proceedButton: some View {
        Button {
            Task {
                await viewModel.validateAndProceed()
            }
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                    Text("Memvalidasi...")
                        .fontWeight(.semibold)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Mulai Ujian")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        viewModel.canProceed && !viewModel.isLoading ?
                        LinearGradient(
                            colors: [.green, .teal],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [.gray.opacity(0.3), .gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .foregroundColor(.white)
        }
        .disabled(!viewModel.canProceed || viewModel.isLoading)
    }

    @ViewBuilder
    private func examDestination(exam: Exam, session: ExamSession) -> some View {
        if exam.type == .googleForm {
            GoogleFormExamView(
                exam: exam,
                session: session,
                viewModel: DIContainer.shared.makeGoogleFormExamViewModel(
                    exam: exam,
                    session: session
                )
            )
        } else {
            StudentExamView(
                exam: exam,
                session: session,
                viewModel: DIContainer.shared.makeStudentExamViewModel(
                    exam: exam,
                    session: session
                )
            )
        }
    }

    private func errorLabel(_ message: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
            Text(message)
                .font(.caption)
        }
        .foregroundColor(.red)
    }
}
