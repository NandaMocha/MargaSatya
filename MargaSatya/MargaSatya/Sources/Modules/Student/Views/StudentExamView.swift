//
//  StudentExamView.swift
//  SecureExamID
//
//  View for In-App exam execution
//

import SwiftUI

struct StudentExamView: View {

    // MARK: - Properties

    let exam: Exam
    let session: ExamSession
    @StateObject private var viewModel: StudentExamViewModel
    @State private var showQuestionGrid = false
    @State private var showSubmitConfirmation = false
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    init(exam: Exam, session: ExamSession, viewModel: StudentExamViewModel) {
        self.exam = exam
        self.session = session
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Bar
                topBar

                // Progress
                progressSection

                // Question Content
                if viewModel.isLoading {
                    loadingView
                } else if let question = viewModel.currentQuestion {
                    questionSection(question: question)
                }

                // Navigation Buttons
                navigationButtons
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
            "Kirim Ujian",
            isPresented: $showSubmitConfirmation
        ) {
            Button("Kirim Sekarang", role: .destructive) {
                Task {
                    await viewModel.submitExam()
                }
            }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Yakin ingin mengirim jawaban? Anda telah menjawab \(viewModel.answeredCount) dari \(viewModel.totalQuestions) soal.")
        }
        .sheet(isPresented: $showQuestionGrid) {
            QuestionGridView(
                questions: viewModel.questions,
                answeredQuestionIds: viewModel.answeredQuestionIds,
                currentIndex: viewModel.currentQuestionIndex
            ) { index in
                viewModel.goToQuestion(index: index)
                showQuestionGrid = false
            }
        }
        .sheet(isPresented: $viewModel.showSubmissionPending) {
            SubmissionPendingView(session: session)
        }
        .fullScreenCover(isPresented: $viewModel.isSubmitted) {
            ExamCompletedView(exam: exam, answeredCount: viewModel.answeredCount, totalQuestions: viewModel.totalQuestions)
        }
        .task {
            await viewModel.loadExam()
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

                Text("Soal \(viewModel.currentQuestionIndex + 1) dari \(viewModel.totalQuestions)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            // Timer (if exam has duration)
            if let _ = exam.durationMinutes, let _ = viewModel.timeRemaining {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    Text(viewModel.timeRemainingFormatted)
                        .font(.headline)
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.orange.opacity(0.2))
                )
            }

            // Question Grid Button
            Button {
                showQuestionGrid = true
            } label: {
                Image(systemName: "square.grid.3x3.fill")
                    .foregroundColor(.white)
                    .font(.title3)
            }
        }
        .padding()
        .background(.ultraThinMaterial.opacity(0.5))
    }

    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Progres: \(viewModel.answeredCount)/\(viewModel.totalQuestions)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                Text("\(Int(viewModel.progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            ProgressView(value: viewModel.progress)
                .tint(.green)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func questionSection(question: ExamQuestion) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Question Number Badge
                HStack {
                    Text("Soal Nomor \(viewModel.currentQuestionIndex + 1)")
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

                    Spacer()

                    // Points
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                        Text("\(question.points) poin")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.yellow)
                }

                // Question Text
                Text(question.text)
                    .font(.body)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)

                // Answer Input
                if question.type == .multipleChoice {
                    multipleChoiceOptions(question: question)
                } else {
                    essayAnswer()
                }
            }
            .padding()
        }
    }

    private func multipleChoiceOptions(question: ExamQuestion) -> some View {
        VStack(spacing: 12) {
            ForEach(Array((question.options ?? []).enumerated()), id: \.offset) { index, option in
                Button {
                    viewModel.currentAnswer = option
                } label: {
                    HStack(spacing: 16) {
                        // Option Letter
                        Text(String(UnicodeScalar(65 + index)!))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(viewModel.currentAnswer == option ? Color.green : Color.white.opacity(0.2))
                            )

                        // Option Text
                        Text(option)
                            .font(.body)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)

                        // Checkmark
                        if viewModel.currentAnswer == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.currentAnswer == option ? Color.green : Color.clear, lineWidth: 2)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func essayAnswer() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Jawaban Anda:")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))

            TextEditor(text: $viewModel.currentAnswer)
                .frame(minHeight: 200)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.1))
                )
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            // Previous Button
            Button {
                viewModel.goToPrevious()
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Sebelumnya")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.canGoPrevious ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                )
                .foregroundColor(.white)
            }
            .disabled(!viewModel.canGoPrevious)

            // Next or Submit Button
            if viewModel.canGoNext {
                Button {
                    viewModel.goToNext()
                } label: {
                    HStack {
                        Text("Selanjutnya")
                        Image(systemName: "chevron.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .foregroundColor(.white)
                }
            } else {
                Button {
                    showSubmitConfirmation = true
                } label: {
                    HStack {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Kirim Jawaban")
                        }
                    }
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
                .disabled(viewModel.isSubmitting)
            }
        }
        .padding()
        .background(.ultraThinMaterial.opacity(0.5))
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)

            Text("Memuat soal ujian...")
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Question Grid View

struct QuestionGridView: View {
    let questions: [ExamQuestion]
    let answeredQuestionIds: Set<String>
    let currentIndex: Int
    let onSelect: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()

                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                            Button {
                                onSelect(index)
                            } label: {
                                VStack(spacing: 4) {
                                    Text("\(index + 1)")
                                        .font(.headline)
                                        .foregroundColor(.white)

                                    if let questionId = question.id, answeredQuestionIds.contains(questionId) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                    }
                                }
                                .frame(height: 60)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            index == currentIndex ?
                                            Color.blue.opacity(0.5) :
                                            (answeredQuestionIds.contains(question.id ?? "") ?
                                             Color.green.opacity(0.3) :
                                             Color.white.opacity(0.1))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(index == currentIndex ? Color.blue : Color.clear, lineWidth: 2)
                                        )
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Navigasi Soal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Tutup") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Exam Completed View

struct ExamCompletedView: View {
    let exam: Exam
    let answeredCount: Int
    let totalQuestions: Int

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

                    Text("Jawaban Anda telah berhasil dikirim")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                // Stats
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        StatItem(icon: "doc.text.fill", value: "\(answeredCount)", label: "Dijawab")
                        StatItem(icon: "list.number", value: "\(totalQuestions)", label: "Total Soal")
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )

                Spacer()

                // Done Button
                Button {
                    // Dismiss all the way back
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

struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
