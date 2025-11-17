//
//  ParticipantSelectionView.swift
//  SecureExamID
//
//  View for selecting exam participants
//

import SwiftUI

struct ParticipantSelectionView: View {

    // MARK: - Properties

    let exam: Exam
    @StateObject private var viewModel: ParticipantSelectionViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    init(exam: Exam, viewModel: ParticipantSelectionViewModel) {
        self.exam = exam
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            GlassBackground()

            VStack(spacing: 0) {
                // Header
                headerSection

                // Search and Actions
                searchAndActionsSection

                // Student List
                if viewModel.isLoading && viewModel.totalStudents == 0 {
                    loadingView
                } else if viewModel.totalStudents == 0 {
                    emptyStateView
                } else {
                    studentListSection
                }

                // Save Button
                saveButtonSection
            }
        }
        .navigationTitle("Kelola Peserta")
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
                dismiss()
            }
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(exam.title)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                StatInfo(
                    icon: "checkmark.circle.fill",
                    value: "\(viewModel.selectedCount)",
                    label: "Dipilih",
                    color: .green
                )

                StatInfo(
                    icon: "person.3.fill",
                    value: "\(viewModel.totalStudents)",
                    label: "Total Siswa",
                    color: .blue
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .padding()
    }

    private var searchAndActionsSection: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Cari nama atau NIS...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )

            // Quick Actions
            HStack(spacing: 12) {
                Button {
                    viewModel.selectAll()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Pilih Semua")
                    }
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                }

                Button {
                    viewModel.deselectAll()
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Hapus Semua")
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                }

                Spacer()
            }
        }
        .padding(.horizontal)
    }

    private var studentListSection: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.studentsToDisplay) { student in
                    ParticipantRow(
                        student: student,
                        isSelected: viewModel.isStudentAllowed(student)
                    ) {
                        viewModel.toggleStudent(student)
                    }
                }
            }
            .padding()
        }
    }

    private var saveButtonSection: some View {
        VStack(spacing: 0) {
            Divider()

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
                        Image(systemName: "checkmark.circle.fill")
                        Text("Simpan Peserta (\(viewModel.selectedCount))")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .foregroundColor(.white)
            }
            .disabled(viewModel.isLoading)
            .padding()
        }
        .background(.ultraThinMaterial)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 80))
                .foregroundColor(.secondary)

            Text("Belum Ada Siswa")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tambahkan siswa terlebih dahulu di menu Data Siswa")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Memuat data siswa...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Participant Row

struct ParticipantRow: View {

    let student: Student
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .green : .secondary)

                // Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .cyan.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(student.name.prefix(1).uppercased())
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(student.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text("NIS: \(student.nis)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Active Badge
                if student.isActive {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat Info

struct StatInfo: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
