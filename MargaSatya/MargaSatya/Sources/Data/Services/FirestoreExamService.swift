//
//  FirestoreExamService.swift
//  MargaSatya
//
//  Firestore implementation for Exam management
//

import Foundation
import FirebaseFirestore

// MARK: - Firestore Exam Service

final class FirestoreExamService: ExamServiceProtocol {

    // MARK: - Properties

    private let db = Firestore.firestore()
    private let collectionName = AppConfiguration.Firebase.Collections.exams

    // MARK: - Get Exam

    func getExam(byCode code: String) async throws -> Exam? {
        let snapshot = try await db.collection(collectionName)
            .whereField("examCode", isEqualTo: code)
            .limit(to: 1)
            .getDocuments()

        guard let document = snapshot.documents.first else {
            return nil
        }

        return try document.data(as: Exam.self)
    }

    func getExam(byId id: String) async throws -> Exam? {
        let document = try await db.collection(collectionName)
            .document(id)
            .getDocument()

        guard document.exists else {
            return nil
        }

        return try document.data(as: Exam.self)
    }

    // MARK: - Create Exam

    func createExam(_ draft: ExamDraft, teacherId: String) async throws -> Exam {
        // Check if exam code is unique
        let existing = try await getExam(byCode: draft.examCode)
        if existing != nil {
            throw ExamServiceError.examCodeAlreadyExists
        }

        let newExam = Exam(
            teacherId: teacherId,
            title: draft.title,
            description: draft.description,
            examCode: draft.examCode,
            type: draft.type,
            formUrl: draft.formUrl,
            startTime: draft.startTime,
            endTime: draft.endTime,
            durationMinutes: draft.durationMinutes
        )

        // Validate exam
        guard newExam.isValid else {
            throw ExamServiceError.invalidExamData(newExam.validationErrors.joined(separator: ", "))
        }

        let docRef = try db.collection(collectionName).addDocument(from: newExam)

        let document = try await docRef.getDocument()
        return try document.data(as: Exam.self)
    }

    // MARK: - Update Exam

    func updateExam(_ exam: Exam) async throws {
        guard let id = exam.id else {
            throw ExamServiceError.invalidExamId
        }

        // Validate exam
        guard exam.isValid else {
            throw ExamServiceError.invalidExamData(exam.validationErrors.joined(separator: ", "))
        }

        try db.collection(collectionName)
            .document(id)
            .setData(from: exam, merge: true)
    }

    // MARK: - Delete Exam

    func deleteExam(examId: String) async throws {
        // Soft delete - mark as inactive
        var exam = try await getExam(byId: examId)
        guard var exam = exam else {
            throw ExamServiceError.examNotFound
        }

        exam.deactivate()
        try await updateExam(exam)
    }

    // MARK: - List Exams

    func listExams(forTeacher teacherId: String) async throws -> [Exam] {
        let snapshot = try await db.collection(collectionName)
            .whereField("teacherId", isEqualTo: teacherId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: Exam.self)
        }
    }

    func listExams(forTeacher teacherId: String, status: ExamStatusFilter) async throws -> [Exam] {
        let allExams = try await listExams(forTeacher: teacherId)

        // Filter by status locally (Firestore doesn't support complex date queries easily)
        return allExams.filter { exam in
            switch status {
            case .all:
                return true
            case .notStarted:
                return exam.status == .scheduled
            case .running:
                return exam.status == .running
            case .finished:
                return exam.status == .finished
            }
        }
    }

    // MARK: - Questions Management

    func listQuestions(forExamId examId: String) async throws -> [ExamQuestion] {
        let snapshot = try await db.collection(collectionName)
            .document(examId)
            .collection(AppConfiguration.Firebase.Subcollections.questions)
            .order(by: "order")
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: ExamQuestion.self)
        }
    }

    func saveQuestions(_ questions: [ExamQuestion], forExamId examId: String) async throws {
        let questionsRef = db.collection(collectionName)
            .document(examId)
            .collection(AppConfiguration.Firebase.Subcollections.questions)

        // Delete existing questions
        let existing = try await questionsRef.getDocuments()
        for document in existing.documents {
            try await document.reference.delete()
        }

        // Add new questions
        for question in questions {
            // Validate question
            guard question.isValid else {
                throw ExamServiceError.invalidQuestionData(question.validationErrors.joined(separator: ", "))
            }

            try questionsRef.addDocument(from: question)
        }

        // Update exam metadata
        var exam = try await getExam(byId: examId)
        exam?.updateMetadata(questions: questions.count, participants: exam?.totalParticipants ?? 0)
        if let exam = exam {
            try await updateExam(exam)
        }
    }

    func addQuestion(_ question: ExamQuestion, forExamId examId: String) async throws {
        guard question.isValid else {
            throw ExamServiceError.invalidQuestionData(question.validationErrors.joined(separator: ", "))
        }

        try db.collection(collectionName)
            .document(examId)
            .collection(AppConfiguration.Firebase.Subcollections.questions)
            .addDocument(from: question)

        // Update count
        let count = try await listQuestions(forExamId: examId).count
        var exam = try await getExam(byId: examId)
        exam?.updateMetadata(questions: count, participants: exam?.totalParticipants ?? 0)
        if let exam = exam {
            try await updateExam(exam)
        }
    }

    func updateQuestion(_ question: ExamQuestion, forExamId examId: String) async throws {
        guard let questionId = question.id else {
            throw ExamServiceError.invalidQuestionId
        }

        guard question.isValid else {
            throw ExamServiceError.invalidQuestionData(question.validationErrors.joined(separator: ", "))
        }

        try db.collection(collectionName)
            .document(examId)
            .collection(AppConfiguration.Firebase.Subcollections.questions)
            .document(questionId)
            .setData(from: question, merge: true)
    }

    func deleteQuestion(questionId: String, forExamId examId: String) async throws {
        try await db.collection(collectionName)
            .document(examId)
            .collection(AppConfiguration.Firebase.Subcollections.questions)
            .document(questionId)
            .delete()

        // Update count
        let count = try await listQuestions(forExamId: examId).count
        var exam = try await getExam(byId: examId)
        exam?.updateMetadata(questions: count, participants: exam?.totalParticipants ?? 0)
        if let exam = exam {
            try await updateExam(exam)
        }
    }

    // MARK: - Participants Management

    func listParticipants(forExamId examId: String) async throws -> [ExamParticipant] {
        let snapshot = try await db.collection(collectionName)
            .document(examId)
            .collection(AppConfiguration.Firebase.Subcollections.participants)
            .order(by: "studentName")
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: ExamParticipant.self)
        }
    }

    func saveParticipants(_ participants: [ExamParticipant], forExamId examId: String) async throws {
        let participantsRef = db.collection(collectionName)
            .document(examId)
            .collection(AppConfiguration.Firebase.Subcollections.participants)

        // Delete existing participants
        let existing = try await participantsRef.getDocuments()
        for document in existing.documents {
            try await document.reference.delete()
        }

        // Add new participants
        for participant in participants {
            try participantsRef.addDocument(from: participant)
        }

        // Update exam metadata
        var exam = try await getExam(byId: examId)
        exam?.updateMetadata(questions: exam?.totalQuestions ?? 0, participants: participants.count)
        if let exam = exam {
            try await updateExam(exam)
        }
    }

    func addParticipant(_ participant: ExamParticipant, forExamId examId: String) async throws {
        try db.collection(collectionName)
            .document(examId)
            .collection(AppConfiguration.Firebase.Subcollections.participants)
            .addDocument(from: participant)

        // Update count
        let count = try await listParticipants(forExamId: examId).count
        var exam = try await getExam(byId: examId)
        exam?.updateMetadata(questions: exam?.totalQuestions ?? 0, participants: count)
        if let exam = exam {
            try await updateExam(exam)
        }
    }

    func removeParticipant(studentId: String, forExamId examId: String) async throws {
        let snapshot = try await db.collection(collectionName)
            .document(examId)
            .collection(AppConfiguration.Firebase.Subcollections.participants)
            .whereField("studentId", isEqualTo: studentId)
            .getDocuments()

        for document in snapshot.documents {
            try await document.reference.delete()
        }

        // Update count
        let count = try await listParticipants(forExamId: examId).count
        var exam = try await getExam(byId: examId)
        exam?.updateMetadata(questions: exam?.totalQuestions ?? 0, participants: count)
        if let exam = exam {
            try await updateExam(exam)
        }
    }

    // MARK: - Uniqueness Check

    func isExamCodeUnique(_ code: String) async throws -> Bool {
        let existing = try await getExam(byCode: code)
        return existing == nil
    }
}

// MARK: - Exam Service Errors

enum ExamServiceError: LocalizedError {
    case examNotFound
    case examCodeAlreadyExists
    case invalidExamId
    case invalidExamData(String)
    case invalidQuestionId
    case invalidQuestionData(String)
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .examNotFound:
            return "Ujian tidak ditemukan"
        case .examCodeAlreadyExists:
            return "Kode ujian sudah digunakan"
        case .invalidExamId:
            return "ID ujian tidak valid"
        case .invalidExamData(let reason):
            return "Data ujian tidak valid: \(reason)"
        case .invalidQuestionId:
            return "ID soal tidak valid"
        case .invalidQuestionData(let reason):
            return "Data soal tidak valid: \(reason)"
        case .permissionDenied:
            return "Anda tidak memiliki izin"
        }
    }
}

// MARK: - Mock Exam Service

final class MockExamService: ExamServiceProtocol {

    // MARK: - Properties

    private var exams: [Exam] = []
    private var questions: [String: [ExamQuestion]] = [:] // examId -> questions
    private var participants: [String: [ExamParticipant]] = [:] // examId -> participants

    var shouldFailOperations = false

    // MARK: - Test Helpers

    func addMockExam(_ exam: Exam) {
        exams.append(exam)
    }

    func reset() {
        exams.removeAll()
        questions.removeAll()
        participants.removeAll()
    }

    // MARK: - Implementation

    func getExam(byCode code: String) async throws -> Exam? {
        if shouldFailOperations {
            throw ExamServiceError.permissionDenied
        }
        return exams.first { $0.examCode == code }
    }

    func getExam(byId id: String) async throws -> Exam? {
        if shouldFailOperations {
            throw ExamServiceError.permissionDenied
        }
        return exams.first { $0.id == id }
    }

    func createExam(_ draft: ExamDraft, teacherId: String) async throws -> Exam {
        if shouldFailOperations {
            throw ExamServiceError.permissionDenied
        }

        let existing = try await getExam(byCode: draft.examCode)
        if existing != nil {
            throw ExamServiceError.examCodeAlreadyExists
        }

        let newExam = Exam(
            id: UUID().uuidString,
            teacherId: teacherId,
            title: draft.title,
            description: draft.description,
            examCode: draft.examCode,
            type: draft.type,
            formUrl: draft.formUrl,
            startTime: draft.startTime,
            endTime: draft.endTime,
            durationMinutes: draft.durationMinutes
        )

        guard newExam.isValid else {
            throw ExamServiceError.invalidExamData(newExam.validationErrors.joined(separator: ", "))
        }

        exams.append(newExam)
        return newExam
    }

    func updateExam(_ exam: Exam) async throws {
        if shouldFailOperations {
            throw ExamServiceError.permissionDenied
        }

        guard exam.isValid else {
            throw ExamServiceError.invalidExamData(exam.validationErrors.joined(separator: ", "))
        }

        guard let index = exams.firstIndex(where: { $0.id == exam.id }) else {
            throw ExamServiceError.examNotFound
        }

        exams[index] = exam
    }

    func deleteExam(examId: String) async throws {
        if shouldFailOperations {
            throw ExamServiceError.permissionDenied
        }

        guard let index = exams.firstIndex(where: { $0.id == examId }) else {
            throw ExamServiceError.examNotFound
        }

        exams[index].deactivate()
    }

    func listExams(forTeacher teacherId: String) async throws -> [Exam] {
        if shouldFailOperations {
            throw ExamServiceError.permissionDenied
        }

        return exams.filter { $0.teacherId == teacherId }
    }

    func listExams(forTeacher teacherId: String, status: ExamStatusFilter) async throws -> [Exam] {
        if shouldFailOperations {
            throw ExamServiceError.permissionDenied
        }

        let allExams = try await listExams(forTeacher: teacherId)
        return allExams.filter { exam in
            switch status {
            case .all:
                return true
            case .notStarted:
                return exam.status == .scheduled
            case .running:
                return exam.status == .running
            case .finished:
                return exam.status == .finished
            }
        }
    }

    func listQuestions(forExamId examId: String) async throws -> [ExamQuestion] {
        if shouldFailOperations {
            throw ExamServiceError.permissionDenied
        }

        return questions[examId] ?? []
    }

    func saveQuestions(_ questions: [ExamQuestion], forExamId examId: String) async throws {
        if shouldFailOperations {
            throw ExamServiceError.permissionDenied
        }

        for question in questions {
            guard question.isValid else {
                throw ExamServiceError.invalidQuestionData(question.validationErrors.joined(separator: ", "))
            }
        }

        self.questions[examId] = questions
    }

    func addQuestion(_ question: ExamQuestion, forExamId examId: String) async throws {
        if shouldFailOperations {
            throw ExamServiceError.permissionDenied
        }

        guard question.isValid else {
            throw ExamServiceError.invalidQuestionData(question.validationErrors.joined(separator: ", "))
        }

        if questions[examId] == nil {
            questions[examId] = []
        }
        questions[examId]?.append(question)
    }

    func updateQuestion(_ question: ExamQuestion, forExamId examId: String) async throws {
        if shouldFailOperations {
            throw ExamServiceError.permissionDenied
        }

        guard let index = questions[examId]?.firstIndex(where: { $0.id == question.id }) else {
            throw ExamServiceError.examNotFound
        }

        questions[examId]?[index] = question
    }

    func deleteQuestion(questionId: String, forExamId examId: String) async throws {
        if shouldFailOperations {
            throw ExamServiceError.permissionDenied
        }

        questions[examId]?.removeAll { $0.id == questionId }
    }

    func listParticipants(forExamId examId: String) async throws -> [ExamParticipant] {
        if shouldFailOperations {
            throw ExamServiceError.permissionDenied
        }

        return participants[examId] ?? []
    }

    func saveParticipants(_ participants: [ExamParticipant], forExamId examId: String) async throws {
        if shouldFailOperations {
            throw ExamServiceError.permissionDenied
        }

        self.participants[examId] = participants
    }

    func addParticipant(_ participant: ExamParticipant, forExamId examId: String) async throws {
        if shouldFailOperations {
            throw ExamServiceError.permissionDenied
        }

        if participants[examId] == nil {
            participants[examId] = []
        }
        participants[examId]?.append(participant)
    }

    func removeParticipant(studentId: String, forExamId examId: String) async throws {
        if shouldFailOperations {
            throw ExamServiceError.permissionDenied
        }

        participants[examId]?.removeAll { $0.studentId == studentId }
    }

    func isExamCodeUnique(_ code: String) async throws -> Bool {
        if shouldFailOperations {
            throw ExamServiceError.permissionDenied
        }

        let existing = try await getExam(byCode: code)
        return existing == nil
    }
}
