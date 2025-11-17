//
//  FirestoreAnswerServiceTests.swift
//  MargaSatyaTests
//
//  Critical tests for answer submission pipeline
//  Tests encryption integration, error handling, and data integrity
//

import Testing
import Foundation
@testable import MargaSatya

@Suite("Firestore Answer Service Tests")
struct FirestoreAnswerServiceTests {

    // MARK: - Test Properties

    let mockService: MockAnswerService
    let encryptionService: MockEncryptionService
    let testSessionId: String
    let testQuestionId: String

    init() {
        self.mockService = MockAnswerService()
        self.encryptionService = MockEncryptionService()
        self.testSessionId = "test-session-123"
        self.testQuestionId = "question-1"
    }

    // MARK: - Save Answer Tests

    @Test("Save answer successfully stores encrypted data")
    func testSaveAnswer_Success() async throws {
        // Arrange
        let plainAnswer = "Jawaban saya untuk pertanyaan 1"
        let encrypted = try encryptionService.encryptAnswer(
            plainText: plainAnswer,
            forQuestionId: testQuestionId,
            sessionId: testSessionId
        )

        // Act
        try await mockService.saveAnswer(sessionId: testSessionId, answer: encrypted)

        // Assert
        let retrieved = try await mockService.getAnswer(
            sessionId: testSessionId,
            questionId: testQuestionId
        )

        #expect(retrieved != nil)
        #expect(retrieved?.questionId == testQuestionId)
        #expect(retrieved?.cipherText == encrypted.cipherText)
    }

    @Test("Save answer overwrites existing answer for same question")
    func testSaveAnswer_OverwritesExisting() async throws {
        // Arrange
        let firstAnswer = "First answer"
        let secondAnswer = "Second answer"

        let encrypted1 = try encryptionService.encryptAnswer(
            plainText: firstAnswer,
            forQuestionId: testQuestionId,
            sessionId: testSessionId
        )

        let encrypted2 = try encryptionService.encryptAnswer(
            plainText: secondAnswer,
            forQuestionId: testQuestionId,
            sessionId: testSessionId
        )

        // Act
        try await mockService.saveAnswer(sessionId: testSessionId, answer: encrypted1)
        try await mockService.saveAnswer(sessionId: testSessionId, answer: encrypted2)

        // Assert
        let answers = try await mockService.listAnswers(sessionId: testSessionId)
        #expect(answers.count == 1)
        #expect(answers.first?.cipherText == encrypted2.cipherText)
    }

    @Test("Save answer fails when service is unavailable")
    func testSaveAnswer_FailsWhenServiceUnavailable() async throws {
        // Arrange
        mockService.shouldFailOperations = true
        let encrypted = try encryptionService.encryptAnswer(
            plainText: "Test",
            forQuestionId: testQuestionId,
            sessionId: testSessionId
        )

        // Act & Assert
        await #expect(throws: AnswerServiceError.self) {
            try await mockService.saveAnswer(sessionId: testSessionId, answer: encrypted)
        }
    }

    @Test("Save answer preserves encryption metadata")
    func testSaveAnswer_PreservesMetadata() async throws {
        // Arrange
        let plainAnswer = "Test answer"
        let encrypted = try encryptionService.encryptAnswer(
            plainText: plainAnswer,
            forQuestionId: testQuestionId,
            sessionId: testSessionId
        )

        // Act
        try await mockService.saveAnswer(sessionId: testSessionId, answer: encrypted)
        let retrieved = try await mockService.getAnswer(
            sessionId: testSessionId,
            questionId: testQuestionId
        )

        // Assert
        #expect(retrieved?.metadata.algorithm == encrypted.metadata.algorithm)
        #expect(retrieved?.metadata.keyVersion == encrypted.metadata.keyVersion)
        #expect(retrieved?.metadata.iv == encrypted.metadata.iv)
    }

    // MARK: - Batch Save Tests

    @Test("Save batch stores multiple answers atomically")
    func testSaveAnswersBatch_Success() async throws {
        // Arrange
        let answers = try (1...5).map { index in
            try encryptionService.encryptAnswer(
                plainText: "Answer \(index)",
                forQuestionId: "question-\(index)",
                sessionId: testSessionId
            )
        }

        // Act
        try await mockService.saveAnswersBatch(sessionId: testSessionId, answers: answers)

        // Assert
        let retrieved = try await mockService.listAnswers(sessionId: testSessionId)
        #expect(retrieved.count == 5)
    }

    @Test("Save batch fails completely when service unavailable")
    func testSaveAnswersBatch_FailsAtomically() async throws {
        // Arrange
        mockService.shouldFailOperations = true
        let answers = try (1...3).map { index in
            try encryptionService.encryptAnswer(
                plainText: "Answer \(index)",
                forQuestionId: "question-\(index)",
                sessionId: testSessionId
            )
        }

        // Act & Assert
        await #expect(throws: AnswerServiceError.self) {
            try await mockService.saveAnswersBatch(sessionId: testSessionId, answers: answers)
        }

        // Verify no partial save
        mockService.shouldFailOperations = false
        let count = try await mockService.getAnsweredCount(sessionId: testSessionId)
        #expect(count == 0)
    }

    @Test("Save batch handles empty array")
    func testSaveAnswersBatch_HandlesEmptyArray() async throws {
        // Act & Assert - Should not throw
        try await mockService.saveAnswersBatch(sessionId: testSessionId, answers: [])

        let count = try await mockService.getAnsweredCount(sessionId: testSessionId)
        #expect(count == 0)
    }

    // MARK: - Retrieve Answer Tests

    @Test("Get answer returns correct encrypted data")
    func testGetAnswer_ReturnsCorrectData() async throws {
        // Arrange
        let plainAnswer = "My encrypted answer"
        let encrypted = try encryptionService.encryptAnswer(
            plainText: plainAnswer,
            forQuestionId: testQuestionId,
            sessionId: testSessionId
        )
        try await mockService.saveAnswer(sessionId: testSessionId, answer: encrypted)

        // Act
        let retrieved = try await mockService.getAnswer(
            sessionId: testSessionId,
            questionId: testQuestionId
        )

        // Assert
        #expect(retrieved != nil)
        let decrypted = try encryptionService.decryptAnswer(retrieved!)
        #expect(decrypted == plainAnswer)
    }

    @Test("Get answer returns nil for non-existent question")
    func testGetAnswer_ReturnsNilForNonExistent() async throws {
        // Act
        let answer = try await mockService.getAnswer(
            sessionId: testSessionId,
            questionId: "non-existent"
        )

        // Assert
        #expect(answer == nil)
    }

    @Test("Get answer returns nil for different session")
    func testGetAnswer_ReturnsNilForDifferentSession() async throws {
        // Arrange
        let encrypted = try encryptionService.encryptAnswer(
            plainText: "Answer",
            forQuestionId: testQuestionId,
            sessionId: testSessionId
        )
        try await mockService.saveAnswer(sessionId: testSessionId, answer: encrypted)

        // Act
        let answer = try await mockService.getAnswer(
            sessionId: "different-session",
            questionId: testQuestionId
        )

        // Assert
        #expect(answer == nil)
    }

    // MARK: - List Answers Tests

    @Test("List answers returns all saved answers")
    func testListAnswers_ReturnsAllAnswers() async throws {
        // Arrange
        let count = 7
        for i in 1...count {
            let encrypted = try encryptionService.encryptAnswer(
                plainText: "Answer \(i)",
                forQuestionId: "question-\(i)",
                sessionId: testSessionId
            )
            try await mockService.saveAnswer(sessionId: testSessionId, answer: encrypted)
        }

        // Act
        let answers = try await mockService.listAnswers(sessionId: testSessionId)

        // Assert
        #expect(answers.count == count)
    }

    @Test("List answers returns empty array for session with no answers")
    func testListAnswers_ReturnsEmptyForNoAnswers() async throws {
        // Act
        let answers = try await mockService.listAnswers(sessionId: testSessionId)

        // Assert
        #expect(answers.isEmpty)
    }

    @Test("List answers only returns answers for specific session")
    func testListAnswers_ReturnsOnlySessionAnswers() async throws {
        // Arrange
        let session1 = "session-1"
        let session2 = "session-2"

        // Add answers to session 1
        for i in 1...3 {
            let encrypted = try encryptionService.encryptAnswer(
                plainText: "S1 Answer \(i)",
                forQuestionId: "q\(i)",
                sessionId: session1
            )
            try await mockService.saveAnswer(sessionId: session1, answer: encrypted)
        }

        // Add answers to session 2
        for i in 1...2 {
            let encrypted = try encryptionService.encryptAnswer(
                plainText: "S2 Answer \(i)",
                forQuestionId: "q\(i)",
                sessionId: session2
            )
            try await mockService.saveAnswer(sessionId: session2, answer: encrypted)
        }

        // Act
        let session1Answers = try await mockService.listAnswers(sessionId: session1)
        let session2Answers = try await mockService.listAnswers(sessionId: session2)

        // Assert
        #expect(session1Answers.count == 3)
        #expect(session2Answers.count == 2)
    }

    // MARK: - Delete Tests

    @Test("Delete all answers removes all data")
    func testDeleteAllAnswers_RemovesAllData() async throws {
        // Arrange
        for i in 1...5 {
            let encrypted = try encryptionService.encryptAnswer(
                plainText: "Answer \(i)",
                forQuestionId: "q\(i)",
                sessionId: testSessionId
            )
            try await mockService.saveAnswer(sessionId: testSessionId, answer: encrypted)
        }

        // Act
        try await mockService.deleteAllAnswers(sessionId: testSessionId)

        // Assert
        let answers = try await mockService.listAnswers(sessionId: testSessionId)
        #expect(answers.isEmpty)
    }

    @Test("Delete all answers only affects specific session")
    func testDeleteAllAnswers_OnlyAffectsSpecificSession() async throws {
        // Arrange
        let session1 = "session-1"
        let session2 = "session-2"

        let e1 = try encryptionService.encryptAnswer(
            plainText: "S1", forQuestionId: "q1", sessionId: session1
        )
        let e2 = try encryptionService.encryptAnswer(
            plainText: "S2", forQuestionId: "q1", sessionId: session2
        )

        try await mockService.saveAnswer(sessionId: session1, answer: e1)
        try await mockService.saveAnswer(sessionId: session2, answer: e2)

        // Act
        try await mockService.deleteAllAnswers(sessionId: session1)

        // Assert
        let s1Answers = try await mockService.listAnswers(sessionId: session1)
        let s2Answers = try await mockService.listAnswers(sessionId: session2)
        #expect(s1Answers.isEmpty)
        #expect(s2Answers.count == 1)
    }

    // MARK: - Utility Tests

    @Test("Has answer returns true for existing answer")
    func testHasAnswer_ReturnsTrueForExisting() async throws {
        // Arrange
        let encrypted = try encryptionService.encryptAnswer(
            plainText: "Answer",
            forQuestionId: testQuestionId,
            sessionId: testSessionId
        )
        try await mockService.saveAnswer(sessionId: testSessionId, answer: encrypted)

        // Act
        let hasAnswer = try await mockService.hasAnswer(
            sessionId: testSessionId,
            questionId: testQuestionId
        )

        // Assert
        #expect(hasAnswer == true)
    }

    @Test("Has answer returns false for non-existent answer")
    func testHasAnswer_ReturnsFalseForNonExistent() async throws {
        // Act
        let hasAnswer = try await mockService.hasAnswer(
            sessionId: testSessionId,
            questionId: "non-existent"
        )

        // Assert
        #expect(hasAnswer == false)
    }

    @Test("Get answered count returns correct number")
    func testGetAnsweredCount_ReturnsCorrectCount() async throws {
        // Arrange
        let expectedCount = 4
        for i in 1...expectedCount {
            let encrypted = try encryptionService.encryptAnswer(
                plainText: "Answer \(i)",
                forQuestionId: "q\(i)",
                sessionId: testSessionId
            )
            try await mockService.saveAnswer(sessionId: testSessionId, answer: encrypted)
        }

        // Act
        let count = try await mockService.getAnsweredCount(sessionId: testSessionId)

        // Assert
        #expect(count == expectedCount)
    }

    @Test("Get answered count returns zero for empty session")
    func testGetAnsweredCount_ReturnsZeroForEmpty() async throws {
        // Act
        let count = try await mockService.getAnsweredCount(sessionId: testSessionId)

        // Assert
        #expect(count == 0)
    }

    // MARK: - Data Integrity Tests

    @Test("Encrypted answer maintains data integrity")
    func testEncryptedAnswer_MaintainsDataIntegrity() async throws {
        // Arrange
        let plainAnswer = "Ini jawaban dengan karakter khusus: é, ñ, 中文, 😀"
        let encrypted = try encryptionService.encryptAnswer(
            plainText: plainAnswer,
            forQuestionId: testQuestionId,
            sessionId: testSessionId
        )

        // Act
        try await mockService.saveAnswer(sessionId: testSessionId, answer: encrypted)
        let retrieved = try await mockService.getAnswer(
            sessionId: testSessionId,
            questionId: testQuestionId
        )

        // Assert
        let decrypted = try encryptionService.decryptAnswer(retrieved!)
        #expect(decrypted == plainAnswer)
    }

    @Test("Long answer text is stored correctly")
    func testLongAnswer_StoredCorrectly() async throws {
        // Arrange
        let longAnswer = String(repeating: "Lorem ipsum dolor sit amet. ", count: 100)
        let encrypted = try encryptionService.encryptAnswer(
            plainText: longAnswer,
            forQuestionId: testQuestionId,
            sessionId: testSessionId
        )

        // Act
        try await mockService.saveAnswer(sessionId: testSessionId, answer: encrypted)
        let retrieved = try await mockService.getAnswer(
            sessionId: testSessionId,
            questionId: testQuestionId
        )

        // Assert
        let decrypted = try encryptionService.decryptAnswer(retrieved!)
        #expect(decrypted == longAnswer)
        #expect(decrypted.count == longAnswer.count)
    }

    // MARK: - Reset Tests

    @Test("Reset clears all test data")
    func testReset_ClearsAllData() async throws {
        // Arrange
        for i in 1...5 {
            let encrypted = try encryptionService.encryptAnswer(
                plainText: "Answer \(i)",
                forQuestionId: "q\(i)",
                sessionId: testSessionId
            )
            try await mockService.saveAnswer(sessionId: testSessionId, answer: encrypted)
        }

        // Act
        mockService.reset()

        // Assert
        let answers = try await mockService.listAnswers(sessionId: testSessionId)
        #expect(answers.isEmpty)
    }
}
