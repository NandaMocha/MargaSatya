//
//  QuestionListView.swift
//  SecureExamID
//
//  View for managing exam questions
//

import SwiftUI

struct QuestionListView: View {

    // MARK: - Properties

    let exam: Exam
    @StateObject private var viewModel: QuestionListViewModel
    @State private var showAddQuestion = false
    @State private var questionToEdit: ExamQuestion?
    @State private var questionToDelete: ExamQuestion?
    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    init(exam: Exam, viewModel: QuestionListViewModel) {
        self.exam = exam
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            GlassBackground()

            VStack(spacing: 0) {
                // Stats Header
                statsHeader

                // Content
                if viewModel.isLoading && !viewModel.hasQuestions {
                    loadingView
                } else if !viewModel.hasQuestions {
                    emptyStateView
                } else {
                    questionListSection
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
        .navigationTitle("Kelola Soal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Tutup") {
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
        .confirmationDialog(
            "Hapus Soal",
            isPresented: $showDeleteConfirmation,
            presenting: questionToDelete
        ) { question in
            Button("Hapus", role: .destructive) {
                Task {
                    await viewModel.deleteQuestion(question)
                }
            }
            Button("Batal", role: .cancel) {
                questionToDelete = nil
            }
        } message: { question in
            Text("Yakin ingin menghapus soal nomor \((question.order ?? 0) + 1)?")
        }
        .sheet(isPresented: $showAddQuestion) {
            NavigationStack {
                QuestionFormView(
                    viewModel: DIContainer.shared.makeQuestionFormViewModel(
                        examId: exam.id ?? "",
                        questionToEdit: nil,
                        currentQuestionCount: viewModel.questionCount
                    )
                ) {
                    showAddQuestion = false
                    Task { await viewModel.refresh() }
                }
            }
        }
        .sheet(item: $questionToEdit) { question in
            NavigationStack {
                QuestionFormView(
                    viewModel: DIContainer.shared.makeQuestionFormViewModel(
                        examId: exam.id ?? "",
                        questionToEdit: question,
                        currentQuestionCount: viewModel.questionCount
                    )
                ) {
                    questionToEdit = nil
                    Task { await viewModel.refresh() }
                }
            }
        }
        .task {
            await viewModel.loadQuestions()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - View Components

    private var statsHeader: some View {
        VStack(spacing: 12) {
            Text(exam.title)
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 16) {
                StatBadge(
                    icon: "list.number",
                    value: "\(viewModel.questionCount)",
                    label: "Total Soal"
                )

                StatBadge(
                    icon: "checkmark.circle",
                    value: "\(viewModel.multipleChoiceCount)",
                    label: "Pilihan Ganda"
                )

                StatBadge(
                    icon: "text.alignleft",
                    value: "\(viewModel.essayCount)",
                    label: "Essay"
                )

                StatBadge(
                    icon: "star.fill",
                    value: "\(viewModel.totalPoints)",
                    label: "Total Poin"
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

    private var questionListSection: some View {
        List {
            ForEach(viewModel.questions) { question in
                QuestionCard(question: question)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        questionToEdit = question
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            questionToDelete = question
                            showDeleteConfirmation = true
                        } label: {
                            Label("Hapus", systemImage: "trash")
                        }

                        Button {
                            questionToEdit = question
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            Task {
                                await viewModel.duplicateQuestion(question)
                            }
                        } label: {
                            Label("Duplikasi", systemImage: "doc.on.doc")
                        }
                        .tint(.orange)
                    }
            }
            .onMove { source, destination in
                Task {
                    await viewModel.moveQuestion(from: source, to: destination)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active)) // Enable drag to reorder
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 80))
                .foregroundColor(.secondary)

            Text("Belum Ada Soal")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tap tombol + untuk menambahkan soal pertama")
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

            Text("Memuat soal...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var addButton: some View {
        Button {
            showAddQuestion = true
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
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
}

// MARK: - Question Card

struct QuestionCard: View {

    let question: ExamQuestion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row
            HStack {
                // Question Number
                Text("No. \((question.order ?? 0) + 1)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )

                // Type Badge
                HStack(spacing: 4) {
                    Image(systemName: question.type == .multipleChoice ? "checkmark.circle" : "text.alignleft")
                        .font(.caption)
                    Text(question.type == .multipleChoice ? "Pilihan Ganda" : "Essay")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(question.type == .multipleChoice ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                )
                .foregroundColor(question.type == .multipleChoice ? .green : .orange)

                Spacer()

                // Points
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                    Text("\(question.points)")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(.yellow)
            }

            // Question Text
            Text(question.text)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(3)

            // Options Preview (for MC)
            if question.type == .multipleChoice, let options = question.options, !options.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(option == question.correctAnswer ? Color.green : Color.secondary.opacity(0.3))
                                .frame(width: 6, height: 6)

                            Text("\(String(UnicodeScalar(65 + index)!)). \(option)")
                                .font(.caption)
                                .foregroundColor(option == question.correctAnswer ? .green : .secondary)
                                .lineLimit(1)
                        }
                    }
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
}

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
