//
//  EncryptionServiceTests.swift
//  MargaSatyaTests
//
//  Unit tests for EncryptionService
//

import Testing
import Foundation
@testable import MargaSatya

@Suite("Encryption Service Tests")
struct EncryptionServiceTests {

    // MARK: - Encryption/Decryption Tests

    @Test("Encrypt and decrypt simple text")
    func testEncryptDecryptSimpleText() async throws {
        let service = EncryptionService()
        let plainText = "Jawaban A"
        let questionId = "q1"
        let sessionId = "session123"

        // Encrypt
        let encrypted = try service.encryptAnswer(
            plainText: plainText,
            forQuestionId: questionId,
            sessionId: sessionId
        )

        #expect(encrypted.questionId == questionId)
        #expect(encrypted.cipherText.count > 0)
        #expect(encrypted.metadata.algorithm == "AES-256-GCM")

        // Decrypt
        let decrypted = try service.decryptAnswer(encrypted)
        #expect(decrypted == plainText)
    }

    @Test("Encrypt and decrypt long text")
    func testEncryptDecryptLongText() async throws {
        let service = EncryptionService()
        let plainText = """
        Pendidikan karakter sangat penting dalam pembentukan kepribadian siswa.
        Melalui pendidikan karakter, siswa dapat mengembangkan nilai-nilai moral,
        etika, dan tanggung jawab yang akan membentuk mereka menjadi individu
        yang lebih baik di masa depan.
        """
        let questionId = "essay1"
        let sessionId = "session456"

        let encrypted = try service.encryptAnswer(
            plainText: plainText,
            forQuestionId: questionId,
            sessionId: sessionId
        )

        let decrypted = try service.decryptAnswer(encrypted)
        #expect(decrypted == plainText)
    }

    @Test("Encrypt and decrypt special characters")
    func testEncryptDecryptSpecialCharacters() async throws {
        let service = EncryptionService()
        let plainText = "Special: @#$%^&*()_+-=[]{}|;:',.<>?/\\"
        let questionId = "q2"
        let sessionId = "session789"

        let encrypted = try service.encryptAnswer(
            plainText: plainText,
            forQuestionId: questionId,
            sessionId: sessionId
        )

        let decrypted = try service.decryptAnswer(encrypted)
        #expect(decrypted == plainText)
    }

    @Test("Encrypt and decrypt Unicode characters")
    func testEncryptDecryptUnicode() async throws {
        let service = EncryptionService()
        let plainText = "Unicode: 你好 مرحبا नमस्ते 🔒🔑"
        let questionId = "q3"
        let sessionId = "session999"

        let encrypted = try service.encryptAnswer(
            plainText: plainText,
            forQuestionId: questionId,
            sessionId: sessionId
        )

        let decrypted = try service.decryptAnswer(encrypted)
        #expect(decrypted == plainText)
    }

    @Test("Empty string encryption")
    func testEncryptDecryptEmptyString() async throws {
        let service = EncryptionService()
        let plainText = ""
        let questionId = "q4"
        let sessionId = "session001"

        let encrypted = try service.encryptAnswer(
            plainText: plainText,
            forQuestionId: questionId,
            sessionId: sessionId
        )

        let decrypted = try service.decryptAnswer(encrypted)
        #expect(decrypted == plainText)
    }

    // MARK: - Encryption Metadata Tests

    @Test("Encryption metadata is correct")
    func testEncryptionMetadata() async throws {
        let service = EncryptionService()
        let plainText = "Test answer"
        let questionId = "q5"
        let sessionId = "session002"

        let encrypted = try service.encryptAnswer(
            plainText: plainText,
            forQuestionId: questionId,
            sessionId: sessionId
        )

        #expect(encrypted.metadata.algorithm == "AES-256-GCM")
        #expect(encrypted.metadata.keyVersion == 1)
        #expect(encrypted.metadata.iv.count == 12) // 96 bits for GCM
        #expect(encrypted.metadata.timestamp <= Date())
    }

    // MARK: - Security Tests

    @Test("Different IVs for same plaintext")
    func testDifferentIVs() async throws {
        let service = EncryptionService()
        let plainText = "Same answer"
        let questionId = "q6"
        let sessionId = "session003"

        let encrypted1 = try service.encryptAnswer(
            plainText: plainText,
            forQuestionId: questionId,
            sessionId: sessionId
        )

        let encrypted2 = try service.encryptAnswer(
            plainText: plainText,
            forQuestionId: questionId,
            sessionId: sessionId
        )

        // Same plaintext should produce different ciphertexts (due to different IVs)
        #expect(encrypted1.metadata.iv != encrypted2.metadata.iv)
        #expect(encrypted1.cipherText != encrypted2.cipherText)

        // But both should decrypt to same plaintext
        let decrypted1 = try service.decryptAnswer(encrypted1)
        let decrypted2 = try service.decryptAnswer(encrypted2)

        #expect(decrypted1 == plainText)
        #expect(decrypted2 == plainText)
    }

    @Test("Tampered ciphertext fails decryption")
    func testTamperedCiphertext() async throws {
        let service = EncryptionService()
        let plainText = "Original answer"
        let questionId = "q7"
        let sessionId = "session004"

        var encrypted = try service.encryptAnswer(
            plainText: plainText,
            forQuestionId: questionId,
            sessionId: sessionId
        )

        // Tamper with ciphertext
        var tampered = encrypted.cipherText
        if tampered.count > 0 {
            tampered[0] ^= 0xFF // Flip bits
        }
        encrypted = EncryptedAnswer(
            questionId: questionId,
            cipherText: tampered,
            metadata: encrypted.metadata
        )

        // Decryption should fail
        #expect(throws: EncryptionError.self) {
            _ = try service.decryptAnswer(encrypted)
        }
    }

    // MARK: - Key Management Tests

    @Test("Ensure encryption key exists")
    func testEnsureKeyExists() async throws {
        let service = EncryptionService()

        // Should not throw
        try service.ensureEncryptionKeyExists()
    }

    @Test("Remove and recreate key")
    func testRemoveAndRecreateKey() async throws {
        let service = EncryptionService()

        // Encrypt something
        let plainText = "Test before removal"
        let encrypted1 = try service.encryptAnswer(
            plainText: plainText,
            forQuestionId: "q8",
            sessionId: "session005"
        )

        // Remove key
        try service.removeEncryptionKey()

        // New encryption creates new key
        let encrypted2 = try service.encryptAnswer(
            plainText: plainText,
            forQuestionId: "q8",
            sessionId: "session005"
        )

        // Both should decrypt correctly
        #expect(try service.decryptAnswer(encrypted1) == plainText)
        #expect(try service.decryptAnswer(encrypted2) == plainText)
    }

    // MARK: - Error Handling Tests

    @Test("Unsupported algorithm throws error")
    func testUnsupportedAlgorithm() async throws {
        let service = EncryptionService()

        let invalidEncrypted = EncryptedAnswer(
            questionId: "q9",
            cipherText: Data(),
            metadata: EncryptionMetadata(
                iv: Data(),
                algorithm: "UNSUPPORTED-ALGO",
                keyVersion: 1
            )
        )

        #expect(throws: EncryptionError.unsupportedAlgorithm("UNSUPPORTED-ALGO")) {
            _ = try service.decryptAnswer(invalidEncrypted)
        }
    }

    // MARK: - Mock Service Tests

    @Test("Mock service encrypts and decrypts")
    func testMockService() async throws {
        let service = MockEncryptionService()
        let plainText = "Mock answer"
        let questionId = "q10"
        let sessionId = "session006"

        let encrypted = try service.encryptAnswer(
            plainText: plainText,
            forQuestionId: questionId,
            sessionId: sessionId
        )

        #expect(encrypted.metadata.algorithm == "MOCK")

        let decrypted = try service.decryptAnswer(encrypted)
        #expect(decrypted == plainText)
    }

    @Test("Mock service can simulate failure")
    func testMockServiceFailure() async throws {
        let service = MockEncryptionService()
        service.shouldFailEncryption = true

        #expect(throws: EncryptionError.self) {
            _ = try service.encryptAnswer(
                plainText: "Test",
                forQuestionId: "q11",
                sessionId: "session007"
            )
        }
    }

    // MARK: - Performance Tests

    @Test("Encrypt multiple answers efficiently")
    func testMultipleEncryptions() async throws {
        let service = EncryptionService()
        let answers = [
            "Answer 1",
            "Answer 2",
            "Answer 3",
            "Answer 4",
            "Answer 5"
        ]

        for (index, answer) in answers.enumerated() {
            let encrypted = try service.encryptAnswer(
                plainText: answer,
                forQuestionId: "q\(index)",
                sessionId: "session008"
            )

            let decrypted = try service.decryptAnswer(encrypted)
            #expect(decrypted == answer)
        }
    }
}
