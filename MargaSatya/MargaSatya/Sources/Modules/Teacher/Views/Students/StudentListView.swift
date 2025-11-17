//
//  StudentListView.swift
//  SecureExamID
//
//  View for displaying and managing student list
//

import SwiftUI

struct StudentListView: View {

    // MARK: - Properties

    @StateObject private var viewModel: StudentListViewModel
    @State private var showAddStudent = false
    @State private var studentToEdit: Student?
    @State private var studentToDelete: Student?
    @State private var showDeleteConfirmation = false

    private let currentUser: User

    // MARK: - Initialization

    init(user: User, viewModel: StudentListViewModel) {
        self.currentUser = user
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            GlassBackground()

            VStack(spacing: 0) {
                // Search bar
                searchSection

                // Content
                if viewModel.isLoading && !viewModel.hasStudents {
                    loadingView
                } else if !viewModel.hasStudents {
                    emptyStateView
                } else {
                    studentListSection
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
        .navigationTitle("Data Siswa")
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
            "Hapus Siswa",
            isPresented: $showDeleteConfirmation,
            presenting: studentToDelete
        ) { student in
            Button("Hapus", role: .destructive) {
                Task {
                    await viewModel.deleteStudent(student)
                }
            }
            Button("Batal", role: .cancel) {
                studentToDelete = nil
            }
        } message: { student in
            Text("Yakin ingin menghapus siswa \(student.name) (NIS: \(student.nis))?")
        }
        .sheet(isPresented: $showAddStudent) {
            NavigationStack {
                StudentFormView(
                    user: currentUser,
                    viewModel: DIContainer.shared.makeStudentFormViewModel(
                        teacherId: currentUser.id ?? "",
                        studentToEdit: nil
                    )
                ) {
                    showAddStudent = false
                    Task { await viewModel.refresh() }
                }
            }
        }
        .sheet(item: $studentToEdit) { student in
            NavigationStack {
                StudentFormView(
                    user: currentUser,
                    viewModel: DIContainer.shared.makeStudentFormViewModel(
                        teacherId: currentUser.id ?? "",
                        studentToEdit: student
                    )
                ) {
                    studentToEdit = nil
                    Task { await viewModel.refresh() }
                }
            }
        }
        .task {
            await viewModel.loadStudents()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - View Components

    private var searchSection: some View {
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
        .padding()
    }

    private var studentListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.studentsToDisplay) { student in
                    StudentCard(student: student)
                        .contextMenu {
                            Button {
                                studentToEdit = student
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                studentToDelete = student
                                showDeleteConfirmation = true
                            } label: {
                                Label("Hapus", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                studentToDelete = student
                                showDeleteConfirmation = true
                            } label: {
                                Label("Hapus", systemImage: "trash")
                            }

                            Button {
                                studentToEdit = student
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                }
            }
            .padding()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 80))
                .foregroundColor(.secondary)

            Text("Belum Ada Siswa")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tap tombol + untuk menambahkan siswa pertama Anda")
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

    private var addButton: some View {
        Button {
            showAddStudent = true
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
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
}

// MARK: - Student Card

struct StudentCard: View {

    let student: Student

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay {
                    Text(student.name.prefix(1).uppercased())
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(student.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    Label(student.nis, systemImage: "number")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if student.isActive {
                        Label("Aktif", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            Spacer()

            // Arrow
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}
