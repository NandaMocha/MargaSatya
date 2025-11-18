//
//  QuestionFormView.swift
//  MargaSatya
//
//  Form view for creating and editing questions
//

import SwiftUI

struct QuestionFormView: View {

    // MARK: - Properties

    @StateObject private var viewModel: QuestionFormViewModel
    @Environment(\.dismiss) private var dismiss

    private let onSave: () -> Void

    // MARK: - Initialization

    init(viewModel: QuestionFormViewModel, onSave: @escaping () -> Void) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onSave = onSave
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            GlassBackground()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Form
                    formSection

                    // Save Button
                    saveButton
                }
                .padding()
            }
        }
        .navigationTitle(viewModel.formTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Batal") {
                    dismiss()
                }
            }
        }
        .alert("Kesalahan", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {
                viewModel.showError = false
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .onChange(of: viewModel.isSaved) { _, isSaved in
            if isSaved {
                onSave()
                dismiss()
            }
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: viewModel.isEditMode ? "text.badge.checkmark" : "text.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(viewModel.formTitle)
                .font(.title2)
                .fontWeight(.bold)

            Text(viewModel.isEditMode ? "Ubah soal di bawah ini" : "Lengkapi soal di bawah ini")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }

    private var formSection: some View {
        VStack(spacing: 20) {
            // Question Type Selection (only for new questions)
            if !viewModel.isEditMode {
                questionTypeSelector
            }

            // Question Text
            VStack(alignment: .leading, spacing: 8) {
                Text("Pertanyaan")
                    .font(.headline)
                    .foregroundColor(.primary)

                TextEditor(text: $viewModel.questionText)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        viewModel.questionTextError != nil ? Color.red.opacity(0.5) : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                    )

                if let error = viewModel.questionTextError {
                    errorLabel(error)
                }
            }

            // Points
            FormField(
                title: "Poin",
                placeholder: "Contoh: 10",
                text: $viewModel.points,
                icon: "star.fill",
                errorMessage: viewModel.pointsError,
                keyboardType: .numberPad
            )

            // Options (for Multiple Choice)
            if viewModel.questionType == .multipleChoice {
                optionsSection
            }
        }
    }

    private var questionTypeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tipe Soal")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 12) {
                // Multiple Choice Option
                TypeButton(
                    title: "Pilihan Ganda",
                    icon: "checkmark.circle",
                    isSelected: viewModel.questionType == .multipleChoice,
                    color: .green
                ) {
                    viewModel.questionType = .multipleChoice
                }

                // Essay Option
                TypeButton(
                    title: "Essay",
                    icon: "text.alignleft",
                    isSelected: viewModel.questionType == .essay,
                    color: .orange
                ) {
                    viewModel.questionType = .essay
                }
            }
        }
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pilihan Jawaban")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                if viewModel.options.count < 6 {
                    Button {
                        viewModel.addOption()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Tambah Opsi")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }

            ForEach(Array(viewModel.options.enumerated()), id: \.offset) { index, option in
                HStack(spacing: 12) {
                    // Option Letter
                    Text(String(UnicodeScalar(65 + index)!))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )

                    // Option Text
                    TextField("Masukkan opsi jawaban", text: $viewModel.options[index])
                        .textFieldStyle(.plain)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            viewModel.optionError(at: index) != nil ? Color.red.opacity(0.5) : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                        )

                    // Correct Answer Selector
                    Button {
                        viewModel.correctAnswer = option
                    } label: {
                        Image(systemName: viewModel.correctAnswer == option ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(viewModel.correctAnswer == option ? .green : .secondary)
                            .font(.title2)
                    }

                    // Delete Button (if more than 2 options)
                    if viewModel.options.count > 2 {
                        Button {
                            viewModel.removeOption(at: index)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                        }
                    }
                }

                if let error = viewModel.optionError(at: index) {
                    errorLabel(error)
                        .padding(.leading, 42)
                }
            }

            // Hint
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .font(.caption)
                Text("Tap ikon ✓ untuk menandai jawaban yang benar")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial)
        )
    }

    private var saveButton: some View {
        Button {
            Task {
                await viewModel.save()
            }
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: viewModel.isEditMode ? "checkmark.circle.fill" : "plus.circle.fill")
                    Text(viewModel.saveButtonTitle)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        viewModel.isFormValid ?
                        LinearGradient(
                            colors: [.blue, .cyan],
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
        .disabled(!viewModel.isFormValid || viewModel.isLoading)
        .padding(.top)
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
