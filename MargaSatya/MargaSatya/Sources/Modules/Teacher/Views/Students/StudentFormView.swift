//
//  StudentFormView.swift
//  SecureExamID
//
//  Form view for creating and editing students
//

import SwiftUI

struct StudentFormView: View {

    // MARK: - Properties

    @StateObject private var viewModel: StudentFormViewModel
    @Environment(\.dismiss) private var dismiss

    private let currentUser: User
    private let onSave: () -> Void

    // MARK: - Initialization

    init(user: User, viewModel: StudentFormViewModel, onSave: @escaping () -> Void) {
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
        .navigationTitle(viewModel.title)
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
            Image(systemName: viewModel.isEditMode ? "person.fill.badge.pencil" : "person.fill.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(viewModel.title)
                .font(.title2)
                .fontWeight(.bold)

            Text(viewModel.isEditMode ? "Ubah data siswa di bawah ini" : "Lengkapi data siswa di bawah ini")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }

    private var formSection: some View {
        VStack(spacing: 20) {
            // Name Field
            FormField(
                title: "Nama Lengkap",
                placeholder: "Masukkan nama lengkap",
                text: $viewModel.name,
                icon: "person.fill",
                errorMessage: viewModel.nameError,
                autocapitalization: .words
            )

            // NIS Field
            FormField(
                title: "NIS (Nomor Induk Siswa)",
                placeholder: "Masukkan NIS",
                text: $viewModel.nis,
                icon: "number",
                errorMessage: viewModel.nisError,
                keyboardType: .default,
                autocapitalization: .none
            )
            .disabled(viewModel.isEditMode) // Don't allow NIS changes when editing

            if viewModel.isEditMode {
                Text("NIS tidak dapat diubah setelah siswa dibuat")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Active Toggle
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
                            colors: [.blue, .purple],
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
}

// MARK: - Form Field Component

struct FormField: View {

    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var errorMessage: String? = nil
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                errorMessage != nil ? Color.red.opacity(0.5) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )

            if let errorMessage = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text(errorMessage)
                        .font(.caption)
                }
                .foregroundColor(.red)
            }
        }
    }
}
