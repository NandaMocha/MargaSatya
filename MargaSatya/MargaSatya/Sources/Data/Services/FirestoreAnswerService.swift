//
//  FirestoreAnswerService.swift
//  MargaSatya
//
//  Firestore implementation for encrypted exam answers
//

import Foundation
import FirebaseFirestore

// MARK: - Firestore Answer Service

final class FirestoreAnswerService: ExamAnswerServiceProtocol {

    // MARK: - Properties

    private let db = Firestore.firestore()
    private let sessionsCollection = AppConfiguration.Firebase.Collections.examSessions
    private let answersSubcollection = AppConfiguration.Firebase.Subcollections.answers

    // MARK: - Save Answer

    func saveAnswer(sessionId: String, answer: EncryptedAnswer) async throws {
        let answerData = try encryptedAnswerToFirestore(answer)

        // Use questionId as document ID for easy retrieval
        try await db.collection(sessionsCollection)
            .document(sessionId)
            .collection(answersSubcollection)
            .document(answer.questionId)
            .setData(answerData, merge: true)
    }

    // MARK: - Save Batch

    func saveAnswersBatch(sessionId: String, answers: [EncryptedAnswer]) async throws {
        let batch = db.batch()

        let answersRef = db.collection(sessionsCollection)
            .document(sessionId)
            .collection(answersSubcollection)

        for answer in answers {
            let answerData = try encryptedAnswerToFirestore(answer)
            let docRef = answersRef.document(answer.questionId)
            batch.setData(answerData, forDocument: docRef, merge: true)
        }

        try await batch.commit()
    }

    // MARK: - Get Answers

    func listAnswers(sessionId: String) async throws -> [EncryptedAnswer] {
        let snapshot = try await db.collection(sessionsCollection)
            .document(sessionId)
            .collection(answersSubcollection)
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            try firestoreToEncryptedAnswer(document.data(), questionId: document.documentID)
        }
    }

    func getAnswer(sessionId: String, questionId: String) async throws -> EncryptedAnswer? {
        let document = try await db.collection(sessionsCollection)
            .document(sessionId)
            .collection(answersSubcollection)
            .document(questionId)
            .getDocument()

        guard document.exists, let data = document.data() else {
            return nil
        }

        return try firestoreToEncryptedAnswer(data, questionId: questionId)
    }

    // MARK: - Delete Answers

    func deleteAllAnswers(sessionId: String) async throws {
        let snapshot = try await db.collection(sessionsCollection)
            .document(sessionId)
            .collection(answersSubcollection)
            .getDocuments()

        let batch = db.batch()
        for document in snapshot.documents {
            batch.deleteDocument(document.reference)
        }

        try await batch.commit()
    }

    // MARK: - Utility

    func hasAnswer(sessionId: String, questionId: String) async throws -> Bool {
        let document = try await db.collection(sessionsCollection)
            .document(sessionId)
            .collection(answersSubcollection)
            .document(questionId)
            .getDocument()

        return document.exists
    }

    func getAnsweredCount(sessionId: String) async throws -> Int {
        let snapshot = try await db.collection(sessionsCollection)
            .document(sessionId)
            .collection(answersSubcollection)
            .getDocuments()

        return snapshot.documents.count
    }

    // MARK: - Private Helpers

    private func encryptedAnswerToFirestore(_ answer: EncryptedAnswer) throws -> [String: Any] {
        return [
            "questionId": answer.questionId,
            "cipherText": answer.cipherText.base64EncodedString(),
            "metadata": [
                "iv": answer.metadata.iv.base64EncodedString(),
                "algorithm": answer.metadata.algorithm,
                "keyVersion": answer.metadata.keyVersion,
                "timestamp": Timestamp(date: answer.metadata.timestamp)
            ],
            "updatedAt": FieldValue.serverTimestamp()
        ]
    }

    private func firestoreToEncryptedAnswer(_ data: [String: Any], questionId: String) throws -> EncryptedAnswer {
        guard let cipherTextString = data["cipherText"] as? String,
              let cipherText = Data(base64Encoded: cipherTextString),
              let metadataDict = data["metadata"] as? [String: Any],
              let ivString = metadataDict["iv"] as? String,
              let iv = Data(base64Encoded: ivString),
              let algorithm = metadataDict["algorithm"] as? String,
              let keyVersion = metadataDict["keyVersion"] as? Int,
              let timestamp = metadataDict["timestamp"] as? Timestamp else {
            throw AnswerServiceError.invalidData
        }

        let metadata = EncryptionMetadata(
            iv: iv,
            algorithm: algorithm,
            keyVersion: keyVersion
        )

        return EncryptedAnswer(
            questionId: questionId,
            cipherText: cipherText,
            metadata: metadata
        )
    }
}

// MARK: - Answer Service Errors

enum AnswerServiceError: LocalizedError {
    case answerNotFound
    case invalidData
    case encryptionFailed
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .answerNotFound:
            return "Jawaban tidak ditemukan"
        case .invalidData:
            return "Data jawaban tidak valid"
        case .encryptionFailed:
            return "Enkripsi gagal"
        case .permissionDenied:
            return "Anda tidak memiliki izin"
        }
    }
}

// MARK: - Mock Answer Service

final class MockAnswerService: ExamAnswerServiceProtocol {

    // MARK: - Properties

    private var answers: [String: [EncryptedAnswer]] = [:] // sessionId -> answers
    var shouldFailOperations = false

    // MARK: - Test Helpers

    func addMockAnswer(_ answer: EncryptedAnswer, forSession sessionId: String) {
        if answers[sessionId] == nil {
            answers[sessionId] = []
        }
        // Remove existing answer for same question if any
        answers[sessionId]?.removeAll { $0.questionId == answer.questionId }
        answers[sessionId]?.append(answer)
    }

    func reset() {
        answers.removeAll()
    }

    // MARK: - Implementation

    func saveAnswer(sessionId: String, answer: EncryptedAnswer) async throws {
        if shouldFailOperations {
            throw AnswerServiceError.permissionDenied
        }

        if answers[sessionId] == nil {
            answers[sessionId] = []
        }

        // Remove existing
        answers[sessionId]?.removeAll { $0.questionId == answer.questionId }
        answers[sessionId]?.append(answer)
    }

    func saveAnswersBatch(sessionId: String, answers: [EncryptedAnswer]) async throws {
        if shouldFailOperations {
            throw AnswerServiceError.permissionDenied
        }

        for answer in answers {
            try await saveAnswer(sessionId: sessionId, answer: answer)
        }
    }

    func listAnswers(sessionId: String) async throws -> [EncryptedAnswer] {
        if shouldFailOperations {
            throw AnswerServiceError.permissionDenied
        }

        return answers[sessionId] ?? []
    }

    func getAnswer(sessionId: String, questionId: String) async throws -> EncryptedAnswer? {
        if shouldFailOperations {
            throw AnswerServiceError.permissionDenied
        }

        return answers[sessionId]?.first { $0.questionId == questionId }
    }

    func deleteAllAnswers(sessionId: String) async throws {
        if shouldFailOperations {
            throw AnswerServiceError.permissionDenied
        }

        answers[sessionId] = []
    }

    func hasAnswer(sessionId: String, questionId: String) async throws -> Bool {
        if shouldFailOperations {
            throw AnswerServiceError.permissionDenied
        }

        let answer = try await getAnswer(sessionId: sessionId, questionId: questionId)
        return answer != nil
    }

    func getAnsweredCount(sessionId: String) async throws -> Int {
        if shouldFailOperations {
            throw AnswerServiceError.permissionDenied
        }

        return answers[sessionId]?.count ?? 0
    }
}
