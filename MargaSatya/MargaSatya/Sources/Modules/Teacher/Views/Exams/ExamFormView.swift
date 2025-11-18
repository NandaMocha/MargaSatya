//
//  ExamFormView.swift
//  MargaSatya
//
//  Form view for creating and editing exams
//

import SwiftUI

struct ExamFormView: View {

    // MARK: - Properties

    @StateObject private var viewModel: ExamFormViewModel
    @Environment(\.dismiss) private var dismiss

    private let currentUser: User
    private let onSave: () -> Void

    // MARK: - Initialization

    init(user: User, viewModel: ExamFormViewModel, onSave: @escaping () -> Void) {
        self.currentUser = user
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
            Image(systemName: viewModel.isEditMode ? "doc.text.fill.badge.pencil" : "doc.text.fill.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(viewModel.formTitle)
                .font(.title2)
                .fontWeight(.bold)

            Text(viewModel.isEditMode ? "Ubah informasi ujian di bawah ini" : "Lengkapi informasi ujian di bawah ini")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }

    private var formSection: some View {
        VStack(spacing: 20) {
            // Exam Type Selection (only for new exams)
            if !viewModel.isEditMode {
                examTypeSelector
            }

            // Title
            FormField(
                title: "Judul Ujian",
                placeholder: "Contoh: Ujian Matematika Kelas 12",
                text: $viewModel.title,
                icon: "text.alignleft",
                errorMessage: viewModel.titleError,
                autocapitalization: .words
            )

            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Deskripsi (Opsional)")
                    .font(.headline)
                    .foregroundColor(.primary)

                TextEditor(text: $viewModel.description)
                    .frame(height: 80)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
            }

            // Access Code
            VStack(alignment: .leading, spacing: 8) {
                Text("Kode Akses")
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)

                    TextField("Kode akses ujian", text: $viewModel.accessCode)
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()

                    Button {
                        viewModel.regenerateAccessCode()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
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

            // Google Form URL (only for Google Form type)
            if viewModel.examType == .googleForm {
                FormField(
                    title: "URL Google Form",
                    placeholder: "https://docs.google.com/forms/...",
                    text: $viewModel.formUrl,
                    icon: "link",
                    errorMessage: viewModel.formUrlError,
                    keyboardType: .URL,
                    autocapitalization: .none
                )
            }

            // Duration
            FormField(
                title: "Durasi (Menit)",
                placeholder: "Contoh: 90",
                text: $viewModel.durationMinutes,
                icon: "clock.fill",
                errorMessage: viewModel.durationError,
                keyboardType: .numberPad
            )

            // Time Limit Toggle
            timeLimitSection

            // Active Status
            VStack(alignment: .leading, spacing: 8) {
                Text("Status")
                    .font(.headline)
                    .foregroundColor(.primary)

                Toggle(isOn: $viewModel.isActive) {
                    HStack {
                        Image(systemName: viewModel.isActive ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(viewModel.isActive ? .green : .red)

                        Text(viewModel.isActive ? "Aktif" : "Tidak Aktif")
                            .foregroundColor(.primary)
                    }
                }
                .tint(.green)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
            }
        }
    }

    private var examTypeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tipe Ujian")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 12) {
                // Google Form Option
                TypeButton(
                    title: "Google Form",
                    icon: "link",
                    isSelected: viewModel.examType == .googleForm,
                    color: .green
                ) {
                    viewModel.examType = .googleForm
                }

                // In-App Option
                TypeButton(
                    title: "In-App",
                    icon: "app.fill",
                    isSelected: viewModel.examType == .inApp,
                    color: .blue
                ) {
                    viewModel.examType = .inApp
                }
            }
        }
    }

    private var timeLimitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $viewModel.hasTimeLimit) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.blue)
                    Text("Atur Waktu Mulai & Selesai")
                        .foregroundColor(.primary)
                }
            }
            .tint(.blue)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )

            if viewModel.hasTimeLimit {
                VStack(spacing: 16) {
                    // Start Date & Time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Waktu Mulai")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        HStack(spacing: 12) {
                            DatePicker("", selection: $viewModel.startDate, displayedComponents: .date)
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.ultraThinMaterial)
                                )

                            DatePicker("", selection: $viewModel.startTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.ultraThinMaterial)
                                )
                        }
                    }

                    // End Date & Time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Waktu Selesai")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        HStack(spacing: 12) {
                            DatePicker("", selection: $viewModel.endDate, displayedComponents: .date)
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.ultraThinMaterial)
                                )

                            DatePicker("", selection: $viewModel.endTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.ultraThinMaterial)
                                )
                        }
                    }

                    if let error = viewModel.timeRangeError {
                        errorLabel(error)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.thinMaterial)
                )
            }
        }
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
                            colors: [.purple, .pink],
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

// MARK: - Type Button

struct TypeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.2) : .ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                    )
            )
            .foregroundColor(isSelected ? color : .secondary)
        }
    }
}
