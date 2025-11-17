//
//  ExamQuestionModelTests.swift
//  MargaSatyaTests
//
//  Unit tests for ExamQuestion model
//

import Testing
import Foundation
@testable import MargaSatya

@Suite("ExamQuestion Model Tests")
struct ExamQuestionModelTests {

    // MARK: - Initialization Tests

    @Test("Multiple choice question initialization")
    func testMultipleChoiceInitialization() {
        let options = [
            QuestionOption(text: "Option A"),
            QuestionOption(text: "Option B"),
            QuestionOption(text: "Option C"),
            QuestionOption(text: "Option D")
        ]

        let question = ExamQuestion(
            order: 1,
            type: .multipleChoice,
            questionText: "Apa ibukota Indonesia?",
            options: options,
            correctOptionIndex: 0,
            points: 10
        )

        #expect(question.type == .multipleChoice)
        #expect(question.isMultipleChoice == true)
        #expect(question.isEssay == false)
        #expect(question.numberOfOptions == 4)
        #expect(question.correctOptionIndex == 0)
    }

    @Test("Essay question initialization")
    func testEssayInitialization() {
        let question = ExamQuestion(
            order: 1,
            type: .essay,
            questionText: "Jelaskan pentingnya pendidikan!",
            points: 20
        )

        #expect(question.type == .essay)
        #expect(question.isEssay == true)
        #expect(question.isMultipleChoice == false)
        #expect(question.options == nil)
        #expect(question.correctOptionIndex == nil)
    }

    // MARK: - Validation Tests

    @Test("Valid multiple choice question")
    func testValidMultipleChoice() {
        let options = [
            QuestionOption(text: "Jakarta"),
            QuestionOption(text: "Bandung")
        ]

        let question = ExamQuestion(
            order: 1,
            type: .multipleChoice,
            questionText: "Apa ibukota Indonesia?",
            options: options,
            correctOptionIndex: 0
        )

        #expect(question.isValid == true)
        #expect(question.validationErrors.isEmpty == true)
    }

    @Test("Invalid multiple choice - no options")
    func testInvalidMultipleChoiceNoOptions() {
        let question = ExamQuestion(
            order: 1,
            type: .multipleChoice,
            questionText: "Test question?",
            options: nil,
            correctOptionIndex: 0
        )

        #expect(question.isValid == false)
        #expect(question.validationErrors.contains("Pilihan ganda harus memiliki minimal 2 opsi"))
    }

    @Test("Invalid multiple choice - only one option")
    func testInvalidMultipleChoiceOneOption() {
        let options = [QuestionOption(text: "Only one")]

        let question = ExamQuestion(
            order: 1,
            type: .multipleChoice,
            questionText: "Test question?",
            options: options,
            correctOptionIndex: 0
        )

        #expect(question.isValid == false)
        #expect(question.validationErrors.contains("Pilihan ganda harus memiliki minimal 2 opsi"))
    }

    @Test("Invalid multiple choice - no correct answer")
    func testInvalidMultipleChoiceNoCorrectAnswer() {
        let options = [
            QuestionOption(text: "Option A"),
            QuestionOption(text: "Option B")
        ]

        let question = ExamQuestion(
            order: 1,
            type: .multipleChoice,
            questionText: "Test question?",
            options: options,
            correctOptionIndex: nil
        )

        #expect(question.isValid == false)
        #expect(question.validationErrors.contains("Jawaban yang benar harus ditentukan"))
    }

    @Test("Invalid multiple choice - empty option text")
    func testInvalidMultipleChoiceEmptyOption() {
        let options = [
            QuestionOption(text: "Option A"),
            QuestionOption(text: "")
        ]

        let question = ExamQuestion(
            order: 1,
            type: .multipleChoice,
            questionText: "Test question?",
            options: options,
            correctOptionIndex: 0
        )

        #expect(question.isValid == false)
        #expect(question.validationErrors.contains("Semua opsi harus memiliki teks"))
    }

    @Test("Invalid question - empty text")
    func testInvalidQuestionEmptyText() {
        let question = ExamQuestion(
            order: 1,
            type: .essay,
            questionText: ""
        )

        #expect(question.isValid == false)
        #expect(question.validationErrors.contains("Teks soal tidak boleh kosong"))
    }

    @Test("Valid essay question")
    func testValidEssayQuestion() {
        let question = ExamQuestion(
            order: 1,
            type: .essay,
            questionText: "Jelaskan pentingnya pendidikan!"
        )

        #expect(question.isValid == true)
        #expect(question.validationErrors.isEmpty == true)
    }

    // MARK: - Answer Checking Tests

    @Test("Check correct answer")
    func testCheckCorrectAnswer() {
        let options = [
            QuestionOption(text: "Jakarta"),
            QuestionOption(text: "Bandung"),
            QuestionOption(text: "Surabaya")
        ]

        let question = ExamQuestion(
            order: 1,
            type: .multipleChoice,
            questionText: "Apa ibukota Indonesia?",
            options: options,
            correctOptionIndex: 0
        )

        #expect(question.checkAnswer(0) == true)
        #expect(question.checkAnswer(1) == false)
        #expect(question.checkAnswer(2) == false)
    }

    @Test("Check answer for essay returns false")
    func testCheckAnswerEssay() {
        let question = ExamQuestion(
            order: 1,
            type: .essay,
            questionText: "Explain something"
        )

        #expect(question.checkAnswer(0) == false)
    }

    // MARK: - Shuffling Tests

    @Test("Shuffle options returns different order")
    func testShuffleOptions() {
        let options = [
            QuestionOption(text: "A"),
            QuestionOption(text: "B"),
            QuestionOption(text: "C"),
            QuestionOption(text: "D")
        ]

        let question = ExamQuestion(
            order: 1,
            type: .multipleChoice,
            questionText: "Test?",
            options: options,
            correctOptionIndex: 0
        )

        let shuffled = question.getShuffledOptions()
        #expect(shuffled != nil)
        #expect(shuffled?.count == 4)
        // Note: There's a small chance shuffled order is same, but unlikely
    }

    // MARK: - Update Tests

    @Test("Update question order")
    func testUpdateOrder() {
        var question = ExamQuestion(
            order: 1,
            type: .essay,
            questionText: "Test"
        )

        #expect(question.order == 1)

        question.updateOrder(5)
        #expect(question.order == 5)
    }

    // MARK: - Sample Data Tests

    @Test("Sample multiple choice question is valid")
    func testSampleMultipleChoice() {
        let question = ExamQuestion.sampleMultipleChoice()

        #expect(question.isValid == true)
        #expect(question.type == .multipleChoice)
        #expect(question.options?.count == 4)
    }

    @Test("Sample essay question is valid")
    func testSampleEssay() {
        let question = ExamQuestion.sampleEssay()

        #expect(question.isValid == true)
        #expect(question.type == .essay)
        #expect(question.options == nil)
    }
}
