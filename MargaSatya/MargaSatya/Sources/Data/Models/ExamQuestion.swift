//
//  ExamQuestion.swift
//  MargaSatya
//
//  Question model for In-App exams
//

import Foundation
import FirebaseFirestore

// MARK: - Question Type

enum QuestionType: String, Codable {
    case multipleChoice = "MULTIPLE_CHOICE"
    case essay = "ESSAY"

    var displayName: String {
        switch self {
        case .multipleChoice:
            return "Pilihan Ganda"
        case .essay:
            return "Esai"
        }
    }
}

// MARK: - Exam Question Model

struct ExamQuestion: Codable, Identifiable {
    @DocumentID var id: String?
    var order: Int // Display order in exam
    let type: QuestionType
    var questionText: String
    var imageUrl: String? // Optional question image
    var options: [QuestionOption]? // For multiple choice only
    var correctOptionIndex: Int? // For multiple choice scoring
    var points: Int // Points for this question
    let createdAt: Date
    var updatedAt: Date

    // MARK: - Additional Settings

    var explanation: String? // Explanation shown after exam
    var tags: [String]? // For categorization

    // MARK: - Initialization

    init(
        id: String? = nil,
        order: Int,
        type: QuestionType,
        questionText: String,
        imageUrl: String? = nil,
        options: [QuestionOption]? = nil,
        correctOptionIndex: Int? = nil,
        points: Int = 1,
        explanation: String? = nil,
        tags: [String]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.order = order
        self.type = type
        self.questionText = questionText
        self.imageUrl = imageUrl
        self.options = options
        self.correctOptionIndex = correctOptionIndex
        self.points = points
        self.explanation = explanation
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    var isMultipleChoice: Bool {
        return type == .multipleChoice
    }

    var isEssay: Bool {
        return type == .essay
    }

    var hasImage: Bool {
        return imageUrl != nil && !(imageUrl?.isEmpty ?? true)
    }

    var numberOfOptions: Int {
        return options?.count ?? 0
    }

    // MARK: - Validation

    var isValid: Bool {
        // Question text cannot be empty
        guard !questionText.isEmpty else {
            return false
        }

        // Type-specific validation
        switch type {
        case .multipleChoice:
            // Must have at least 2 options
            guard let options = options, options.count >= 2 else {
                return false
            }

            // Must have a correct answer
            guard let correctIndex = correctOptionIndex,
                  correctIndex >= 0,
                  correctIndex < options.count else {
                return false
            }

            // All options must have non-empty text
            return options.allSatisfy { !$0.text.isEmpty }

        case .essay:
            // Essay questions are valid if they have question text
            return true
        }
    }

    var validationErrors: [String] {
        var errors: [String] = []

        if questionText.isEmpty {
            errors.append("Teks soal tidak boleh kosong")
        }

        switch type {
        case .multipleChoice:
            if options == nil || options!.count < 2 {
                errors.append("Pilihan ganda harus memiliki minimal 2 opsi")
            }

            if let options = options {
                if options.contains(where: { $0.text.isEmpty }) {
                    errors.append("Semua opsi harus memiliki teks")
                }
            }

            if correctOptionIndex == nil {
                errors.append("Jawaban yang benar harus ditentukan")
            } else if let correctIndex = correctOptionIndex,
                      let optionCount = options?.count,
                      (correctIndex < 0 || correctIndex >= optionCount) {
                errors.append("Indeks jawaban yang benar tidak valid")
            }

        case .essay:
            break // Essay questions only need question text
        }

        if points < 0 {
            errors.append("Poin tidak boleh negatif")
        }

        return errors
    }

    // MARK: - Methods

    mutating func updateOrder(_ newOrder: Int) {
        self.order = newOrder
        self.updatedAt = Date()
    }

    /// Check if provided answer is correct (for multiple choice)
    func checkAnswer(_ answerIndex: Int) -> Bool {
        guard type == .multipleChoice,
              let correctIndex = correctOptionIndex else {
            return false
        }
        return answerIndex == correctIndex
    }

    /// Get shuffled options (for randomization)
    func getShuffledOptions() -> [QuestionOption]? {
        return options?.shuffled()
    }
}

// MARK: - Question Option

struct QuestionOption: Codable {
    let text: String
    let imageUrl: String?

    init(text: String, imageUrl: String? = nil) {
        self.text = text
        self.imageUrl = imageUrl
    }
}

// MARK: - Question Option Extensions

extension QuestionOption {
    var hasImage: Bool {
        return imageUrl != nil && !(imageUrl?.isEmpty ?? true)
    }
}

// MARK: - Equatable

extension QuestionOption: Equatable {
    static func == (lhs: QuestionOption, rhs: QuestionOption) -> Bool {
        return lhs.text == rhs.text && lhs.imageUrl == rhs.imageUrl
    }
}

extension ExamQuestion: Equatable {
    static func == (lhs: ExamQuestion, rhs: ExamQuestion) -> Bool {
        return lhs.id == rhs.id
    }
}

extension ExamQuestion: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Sample Data (for testing)

extension ExamQuestion {
    static func sampleMultipleChoice(order: Int = 1) -> ExamQuestion {
        return ExamQuestion(
            order: order,
            type: .multipleChoice,
            questionText: "Apa ibukota Indonesia?",
            options: [
                QuestionOption(text: "Jakarta"),
                QuestionOption(text: "Bandung"),
                QuestionOption(text: "Surabaya"),
                QuestionOption(text: "Medan")
            ],
            correctOptionIndex: 0,
            points: 10
        )
    }

    static func sampleEssay(order: Int = 1) -> ExamQuestion {
        return ExamQuestion(
            order: order,
            type: .essay,
            questionText: "Jelaskan pentingnya pendidikan karakter di sekolah!",
            points: 20
        )
    }
}
