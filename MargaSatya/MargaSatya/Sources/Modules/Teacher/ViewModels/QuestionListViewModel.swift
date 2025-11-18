//
//  QuestionListViewModel.swift
//  MargaSatya
//
//  ViewModel for managing exam questions
//

import SwiftUI

@MainActor
final class QuestionListViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var questions: [ExamQuestion] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // MARK: - Private Properties

    private let examService: ExamServiceProtocol
    private let examId: String

    // MARK: - Computed Properties

    var hasQuestions: Bool {
        !questions.isEmpty
    }

    var questionCount: Int {
        questions.count
    }

    var totalPoints: Int {
        questions.reduce(0) { $0 + $1.points }
    }

    var multipleChoiceCount: Int {
        questions.filter { $0.type == .multipleChoice }.count
    }

    var essayCount: Int {
        questions.filter { $0.type == .essay }.count
    }

    // MARK: - Initialization

    init(examService: ExamServiceProtocol, examId: String) {
        self.examService = examService
        self.examId = examId
    }

    // MARK: - Public Methods

    func loadQuestions() async {
        isLoading = true
        errorMessage = nil

        do {
            questions = try await examService.getQuestions(forExamId: examId)
            questions.sort { ($0.order ?? 0) < ($1.order ?? 0) }
        } catch {
            errorMessage = "Gagal memuat soal: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func deleteQuestion(_ question: ExamQuestion) async {
        isLoading = true
        errorMessage = nil

        do {
            // Remove from local array first for immediate UI update
            questions.removeAll { $0.id == question.id }

            // Update order numbers
            updateQuestionOrder()

            // Save updated list to Firestore
            try await examService.saveQuestions(questions, forExamId: examId)
        } catch {
            errorMessage = "Gagal menghapus soal: \(error.localizedDescription)"
            showError = true
            // Reload on error
            await loadQuestions()
        }

        isLoading = false
    }

    func moveQuestion(from source: IndexSet, to destination: Int) async {
        questions.move(fromOffsets: source, toOffset: destination)
        updateQuestionOrder()

        // Save reordered list
        do {
            try await examService.saveQuestions(questions, forExamId: examId)
        } catch {
            errorMessage = "Gagal mengubah urutan: \(error.localizedDescription)"
            showError = true
            await loadQuestions() // Reload on error
        }
    }

    func duplicateQuestion(_ question: ExamQuestion) async {
        isLoading = true
        errorMessage = nil

        do {
            var newQuestion = question
            newQuestion.id = nil // Clear ID to create new
            newQuestion.text = "\(question.text) (Salinan)"
            newQuestion.order = questions.count

            questions.append(newQuestion)

            try await examService.saveQuestions(questions, forExamId: examId)
            await loadQuestions() // Reload to get new ID
        } catch {
            errorMessage = "Gagal menduplikasi soal: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func refresh() async {
        await loadQuestions()
    }

    // MARK: - Private Methods

    private func updateQuestionOrder() {
        for (index, _) in questions.enumerated() {
            questions[index].order = index
        }
    }
}
