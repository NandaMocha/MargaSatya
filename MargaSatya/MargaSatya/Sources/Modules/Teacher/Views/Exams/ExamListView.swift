//
//  ExamListView.swift
//  SecureExamID
//
//  View for displaying and managing exam list
//

import SwiftUI

struct ExamListView: View {

    // MARK: - Properties

    @StateObject private var viewModel: ExamListViewModel
    @State private var showAddExam = false
    @State private var examToEdit: Exam?
    @State private var examToDelete: Exam?
    @State private var examForQuestions: Exam?
    @State private var examForParticipants: Exam?
    @State private var showDeleteConfirmation = false

    private let currentUser: User

    // MARK: - Initialization

    init(user: User, viewModel: ExamListViewModel) {
        self.currentUser = user
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            GlassBackground()

            VStack(spacing: 0) {
                // Search and Filters
                searchAndFilterSection

                // Content
                if viewModel.isLoading && !viewModel.hasExams {
                    loadingView
                } else if !viewModel.hasExams {
                    emptyStateView
                } else {
                    examListSection
                }
            }

            // Floating Add Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    addButton
                }
            }
            .padding()
        }
        .navigationTitle("Data Ujian")
        .navigationBarTitleDisplayMode(.large)
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
            "Hapus Ujian",
            isPresented: $showDeleteConfirmation,
            presenting: examToDelete
        ) { exam in
            Button("Hapus", role: .destructive) {
                Task {
                    await viewModel.deleteExam(exam)
                }
            }
            Button("Batal", role: .cancel) {
                examToDelete = nil
            }
        } message: { exam in
            Text("Yakin ingin menghapus ujian \"\(exam.title)\"? Tindakan ini tidak dapat dibatalkan.")
        }
        .sheet(isPresented: $showAddExam) {
            NavigationStack {
                ExamFormView(
                    user: currentUser,
                    viewModel: DIContainer.shared.makeExamFormViewModel(
                        teacherId: currentUser.id ?? "",
                        examToEdit: nil
                    )
                ) {
                    showAddExam = false
                    Task { await viewModel.refresh() }
                }
            }
        }
        .sheet(item: $examToEdit) { exam in
            NavigationStack {
                ExamFormView(
                    user: currentUser,
                    viewModel: DIContainer.shared.makeExamFormViewModel(
                        teacherId: currentUser.id ?? "",
                        examToEdit: exam
                    )
                ) {
                    examToEdit = nil
                    Task { await viewModel.refresh() }
                }
            }
        }
        .sheet(item: $examForQuestions) { exam in
            NavigationStack {
                QuestionListView(
                    exam: exam,
                    viewModel: DIContainer.shared.makeQuestionListViewModel(examId: exam.id ?? "")
                )
            }
        }
        .sheet(item: $examForParticipants) { exam in
            NavigationStack {
                ParticipantSelectionView(
                    exam: exam,
                    viewModel: DIContainer.shared.makeParticipantSelectionViewModel(
                        examId: exam.id ?? "",
                        teacherId: currentUser.id ?? ""
                    )
                )
            }
        }
        .task {
            await viewModel.loadExams()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - View Components

    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Cari judul atau kode akses...", text: $viewModel.searchText)
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

            // Filters
            HStack(spacing: 12) {
                // Type Filter
                Menu {
                    ForEach(ExamListViewModel.ExamTypeFilter.allCases, id: \.self) { filter in
                        Button {
                            viewModel.selectedTypeFilter = filter
                        } label: {
                            HStack {
                                Text(filter.rawValue)
                                if viewModel.selectedTypeFilter == filter {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "doc.text")
                        Text(viewModel.selectedTypeFilter.rawValue)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                    .foregroundColor(.primary)
                }

                // Status Filter
                Menu {
                    ForEach(ExamListViewModel.ExamStatusFilter.allCases, id: \.self) { filter in
                        Button {
                            viewModel.selectedStatusFilter = filter
                        } label: {
                            HStack {
                                Text(filter.rawValue)
                                if viewModel.selectedStatusFilter == filter {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.caption2)
                        Text(viewModel.selectedStatusFilter.rawValue)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                    .foregroundColor(.primary)
                }

                Spacer()
            }
        }
        .padding()
    }

    private var examListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.examsToDisplay) { exam in
                    ExamCard(exam: exam)
                        .contextMenu {
                            Button {
                                examToEdit = exam
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }

                            if exam.type == .inApp {
                                Button {
                                    examForQuestions = exam
                                } label: {
                                    Label("Kelola Soal", systemImage: "list.bullet.rectangle")
                                }
                            }

                            Button {
                                examForParticipants = exam
                            } label: {
                                Label("Kelola Peserta", systemImage: "person.2")
                            }

                            Button {
                                Task {
                                    await viewModel.duplicateExam(exam)
                                }
                            } label: {
                                Label("Duplikasi", systemImage: "doc.on.doc")
                            }

                            Divider()

                            Button(role: .destructive) {
                                examToDelete = exam
                                showDeleteConfirmation = true
                            } label: {
                                Label("Hapus", systemImage: "trash")
                            }
                        }
                        .onTapGesture {
                            examToEdit = exam
                        }
                }
            }
            .padding()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 80))
                .foregroundColor(.secondary)

            Text("Belum Ada Ujian")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tap tombol + untuk membuat ujian pertama Anda")
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

            Text("Memuat data ujian...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var addButton: some View {
        Button {
            showAddExam = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
}

// MARK: - Exam Card

struct ExamCard: View {

    let exam: Exam

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row
            HStack {
                // Type Badge
                HStack(spacing: 4) {
                    Image(systemName: exam.type == .googleForm ? "link" : "app.fill")
                        .font(.caption)
                    Text(exam.type == .googleForm ? "Google Form" : "In-App")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(exam.type == .googleForm ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                )
                .foregroundColor(exam.type == .googleForm ? .green : .blue)

                Spacer()

                // Status Badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(exam.status.color)
                        .frame(width: 8, height: 8)
                    Text(exam.status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(exam.status.color.opacity(0.2))
                )
                .foregroundColor(exam.status.color)
            }

            // Title
            Text(exam.title)
                .font(.headline)
                .foregroundColor(.primary)

            // Description
            if let description = exam.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Info Row
            HStack(spacing: 16) {
                Label(exam.accessCode, systemImage: "key.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let duration = exam.durationMinutes {
                    Label("\(duration) menit", systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if exam.isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }

            // Time Info
            if let startTime = exam.startTime, let endTime = exam.endTime {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(formatDate(startTime))
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("\(formatTime(startTime)) - \(formatTime(endTime))")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "id_ID")
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "id_ID")
        return formatter.string(from: date)
    }
}

// MARK: - ExamStatus Extension

extension ExamStatus {
    var displayName: String {
        switch self {
        case .ready: return "Siap"
        case .scheduled: return "Terjadwal"
        case .running: return "Berlangsung"
        case .finished: return "Selesai"
        case .inactive: return "Tidak Aktif"
        }
    }

    var color: Color {
        switch self {
        case .ready: return .blue
        case .scheduled: return .orange
        case .running: return .green
        case .finished: return .gray
        case .inactive: return .red
        }
    }
}
