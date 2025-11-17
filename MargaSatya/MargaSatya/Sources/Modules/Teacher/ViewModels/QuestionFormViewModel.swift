//
//  QuestionFormViewModel.swift
//  SecureExamID
//
//  ViewModel for creating and editing exam questions
//

import SwiftUI

@MainActor
final class QuestionFormViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var questionType: QuestionType = .multipleChoice
    @Published var questionText: String = ""
    @Published var points: String = "10"
    @Published var options: [String] = ["", "", "", ""]
    @Published var correctAnswer: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var isSaved: Bool = false

    // MARK: - Private Properties

    private let examService: ExamServiceProtocol
    private let examId: String
    private let questionToEdit: ExamQuestion?
    private let currentQuestionCount: Int

    // MARK: - Computed Properties

    var isEditMode: Bool {
        questionToEdit != nil
    }

    var formTitle: String {
        isEditMode ? "Edit Soal" : "Tambah Soal"
    }

    var saveButtonTitle: String {
        isEditMode ? "Simpan Perubahan" : "Tambah Soal"
    }

    var isFormValid: Bool {
        let basicValid = !questionText.trimmingCharacters(in: .whitespaces).isEmpty &&
                        Int(points) != nil &&
                        (Int(points) ?? 0) > 0

        switch questionType {
        case .multipleChoice:
            let hasAllOptions = options.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            let hasCorrectAnswer = !correctAnswer.isEmpty && options.contains(correctAnswer)
            return basicValid && hasAllOptions && hasCorrectAnswer
        case .essay:
            return basicValid
        }
    }

    var questionTextError: String? {
        guard !questionText.isEmpty else { return nil }
        let trimmed = questionText.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return "Pertanyaan tidak boleh kosong"
        }
        if trimmed.count < 10 {
            return "Pertanyaan minimal 10 karakter"
        }
        return nil
    }

    var pointsError: String? {
        guard !points.isEmpty else { return nil }
        if let pointValue = Int(points) {
            if pointValue < 1 {
                return "Poin minimal 1"
            }
            if pointValue > 100 {
                return "Poin maksimal 100"
            }
        } else {
            return "Poin harus berupa angka"
        }
        return nil
    }

    // MARK: - Initialization

    init(examService: ExamServiceProtocol, examId: String, questionToEdit: ExamQuestion?, currentQuestionCount: Int) {
        self.examService = examService
        self.examId = examId
        self.questionToEdit = questionToEdit
        self.currentQuestionCount = currentQuestionCount

        // Populate fields if editing
        if let question = questionToEdit {
            self.questionType = question.type
            self.questionText = question.text
            self.points = String(question.points)

            if question.type == .multipleChoice {
                if let opts = question.options {
                    // Ensure we have at least 4 options
                    self.options = opts
                    while self.options.count < 4 {
                        self.options.append("")
                    }
                }
                self.correctAnswer = question.correctAnswer ?? ""
            }
        }
    }

    // MARK: - Public Methods

    func save() async {
        guard isFormValid else {
            errorMessage = "Mohon lengkapi semua field dengan benar"
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let trimmedText = questionText.trimmingCharacters(in: .whitespaces)
            let pointValue = Int(points) ?? 10

            // Load all questions to update or append
            var allQuestions = try await examService.getQuestions(forExamId: examId)

            if isEditMode, let questionToUpdate = questionToEdit {
                // Find and update the question
                if let index = allQuestions.firstIndex(where: { $0.id == questionToUpdate.id }) {
                    allQuestions[index].text = trimmedText
                    allQuestions[index].type = questionType
                    allQuestions[index].points = pointValue

                    if questionType == .multipleChoice {
                        allQuestions[index].options = options.map { $0.trimmingCharacters(in: .whitespaces) }
                        allQuestions[index].correctAnswer = correctAnswer
                    } else {
                        allQuestions[index].options = nil
                        allQuestions[index].correctAnswer = nil
                    }
                }
            } else {
                // Create new question
                var newQuestion = ExamQuestion(
                    text: trimmedText,
                    type: questionType,
                    points: pointValue,
                    order: currentQuestionCount
                )

                if questionType == .multipleChoice {
                    newQuestion.options = options.map { $0.trimmingCharacters(in: .whitespaces) }
                    newQuestion.correctAnswer = correctAnswer
                }

                allQuestions.append(newQuestion)
            }

            // Validate all questions
            for question in allQuestions {
                if !question.isValid {
                    throw ExamServiceError.invalidQuestionData("Soal tidak valid: \(question.validationErrors.joined(separator: ", "))")
                }
            }

            // Save all questions
            try await examService.saveQuestions(allQuestions, forExamId: examId)

            isSaved = true
        } catch ExamServiceError.invalidQuestionData(let message) {
            errorMessage = message
            showError = true
        } catch {
            errorMessage = "Gagal menyimpan soal: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func addOption() {
        if options.count < 6 { // Max 6 options
            options.append("")
        }
    }

    func removeOption(at index: Int) {
        guard options.count > 2 else { return } // Min 2 options
        let removedOption = options[index]
        options.remove(at: index)

        // Clear correct answer if it was the removed option
        if correctAnswer == removedOption {
            correctAnswer = ""
        }
    }

    func optionError(at index: Int) -> String? {
        guard index < options.count else { return nil }
        let option = options[index]
        guard !option.isEmpty else { return nil }

        let trimmed = option.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return "Opsi tidak boleh kosong"
        }
        return nil
    }
}
