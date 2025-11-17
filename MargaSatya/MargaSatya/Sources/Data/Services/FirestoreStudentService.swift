//
//  FirestoreStudentService.swift
//  SecureExamID
//
//  Firestore implementation for Student management
//

import Foundation
import FirebaseFirestore

// MARK: - Firestore Student Service

final class FirestoreStudentService: StudentServiceProtocol {

    // MARK: - Properties

    private let db = Firestore.firestore()
    private let collectionName = AppConfiguration.Firebase.Collections.students

    // MARK: - Get Student by NIS

    func getStudent(byNIS nis: String, teacherId: String?) async throws -> Student? {
        var query: Query = db.collection(collectionName)
            .whereField("nis", isEqualTo: nis)

        // Filter by teacher if provided
        if let teacherId = teacherId {
            query = query.whereField("teacherId", isEqualTo: teacherId)
        }

        let snapshot = try await query.getDocuments()

        guard let document = snapshot.documents.first else {
            return nil
        }

        return try document.data(as: Student.self)
    }

    // MARK: - Get Student by ID

    func getStudent(byId id: String) async throws -> Student? {
        let document = try await db.collection(collectionName)
            .document(id)
            .getDocument()

        guard document.exists else {
            return nil
        }

        return try document.data(as: Student.self)
    }

    // MARK: - Create Student

    func createStudent(_ student: StudentDraft, teacherId: String) async throws -> Student {
        // Check if NIS already exists for this teacher
        let existing = try await getStudent(byNIS: student.nis, teacherId: teacherId)
        if existing != nil {
            throw StudentServiceError.nisAlreadyExists
        }

        let newStudent = Student(
            teacherId: teacherId,
            nis: student.nis,
            name: student.name,
            className: student.className,
            additionalInfo: student.additionalInfo
        )

        let docRef = try db.collection(collectionName).addDocument(from: newStudent)

        // Fetch the created document to get the ID
        let document = try await docRef.getDocument()
        return try document.data(as: Student.self)
    }

    // MARK: - Update Student

    func updateStudent(_ student: Student) async throws {
        guard let id = student.id else {
            throw StudentServiceError.invalidStudentId
        }

        try db.collection(collectionName)
            .document(id)
            .setData(from: student, merge: true)
    }

    // MARK: - Delete Student

    func deleteStudent(studentId: String) async throws {
        // Soft delete - just mark as inactive
        var student = try await getStudent(byId: studentId)
        guard var student = student else {
            throw StudentServiceError.studentNotFound
        }

        student.deactivate()
        try await updateStudent(student)
    }

    // MARK: - List Students

    func listStudents(forTeacher teacherId: String) async throws -> [Student] {
        let snapshot = try await db.collection(collectionName)
            .whereField("teacherId", isEqualTo: teacherId)
            .order(by: "name")
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: Student.self)
        }
    }

    // MARK: - List Active Students

    func listActiveStudents(forTeacher teacherId: String) async throws -> [Student] {
        let snapshot = try await db.collection(collectionName)
            .whereField("teacherId", isEqualTo: teacherId)
            .whereField("isActive", isEqualTo: true)
            .order(by: "name")
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: Student.self)
        }
    }

    // MARK: - Check if Student Allowed

    func isStudentAllowed(nis: String, examId: String) async throws -> Bool {
        // Check in ExamParticipant subcollection
        let participantsRef = db.collection(AppConfiguration.Firebase.Collections.exams)
            .document(examId)
            .collection(AppConfiguration.Firebase.Subcollections.participants)

        let snapshot = try await participantsRef
            .whereField("nis", isEqualTo: nis)
            .whereField("allowed", isEqualTo: true)
            .limit(to: 1)
            .getDocuments()

        return !snapshot.documents.isEmpty
    }

    // MARK: - Search Students

    func searchStudents(query: String, teacherId: String) async throws -> [Student] {
        // Firestore doesn't support full-text search natively
        // Get all students and filter locally
        let allStudents = try await listStudents(forTeacher: teacherId)

        return allStudents.filter { student in
            student.matches(query: query)
        }
    }

    // MARK: - Check NIS Uniqueness

    func isNISUnique(_ nis: String, teacherId: String) async throws -> Bool {
        let existing = try await getStudent(byNIS: nis, teacherId: teacherId)
        return existing == nil
    }
}

// MARK: - Student Service Errors

enum StudentServiceError: LocalizedError {
    case studentNotFound
    case nisAlreadyExists
    case invalidStudentId
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .studentNotFound:
            return "Siswa tidak ditemukan"
        case .nisAlreadyExists:
            return "NIS sudah terdaftar"
        case .invalidStudentId:
            return "ID siswa tidak valid"
        case .permissionDenied:
            return "Anda tidak memiliki izin"
        }
    }
}

// MARK: - Mock Student Service

final class MockStudentService: StudentServiceProtocol {

    // MARK: - Properties

    private var students: [Student] = []
    private var participants: [String: [ExamParticipant]] = [:] // examId -> participants

    var shouldFailOperations = false

    // MARK: - Test Helpers

    func addMockStudent(_ student: Student) {
        students.append(student)
    }

    func addMockParticipant(_ participant: ExamParticipant, forExam examId: String) {
        if participants[examId] == nil {
            participants[examId] = []
        }
        participants[examId]?.append(participant)
    }

    func reset() {
        students.removeAll()
        participants.removeAll()
    }

    // MARK: - Implementation

    func getStudent(byNIS nis: String, teacherId: String?) async throws -> Student? {
        if shouldFailOperations {
            throw StudentServiceError.permissionDenied
        }

        return students.first { student in
            student.nis == nis &&
            (teacherId == nil || student.teacherId == teacherId)
        }
    }

    func getStudent(byId id: String) async throws -> Student? {
        if shouldFailOperations {
            throw StudentServiceError.permissionDenied
        }

        return students.first { $0.id == id }
    }

    func createStudent(_ student: StudentDraft, teacherId: String) async throws -> Student {
        if shouldFailOperations {
            throw StudentServiceError.permissionDenied
        }

        // Check uniqueness
        let existing = try await getStudent(byNIS: student.nis, teacherId: teacherId)
        if existing != nil {
            throw StudentServiceError.nisAlreadyExists
        }

        let newStudent = Student(
            id: UUID().uuidString,
            teacherId: teacherId,
            nis: student.nis,
            name: student.name,
            className: student.className,
            additionalInfo: student.additionalInfo
        )

        students.append(newStudent)
        return newStudent
    }

    func updateStudent(_ student: Student) async throws {
        if shouldFailOperations {
            throw StudentServiceError.permissionDenied
        }

        guard let index = students.firstIndex(where: { $0.id == student.id }) else {
            throw StudentServiceError.studentNotFound
        }

        students[index] = student
    }

    func deleteStudent(studentId: String) async throws {
        if shouldFailOperations {
            throw StudentServiceError.permissionDenied
        }

        guard let index = students.firstIndex(where: { $0.id == studentId }) else {
            throw StudentServiceError.studentNotFound
        }

        students[index].deactivate()
    }

    func listStudents(forTeacher teacherId: String) async throws -> [Student] {
        if shouldFailOperations {
            throw StudentServiceError.permissionDenied
        }

        return students
            .filter { $0.teacherId == teacherId }
            .sorted { $0.name < $1.name }
    }

    func listActiveStudents(forTeacher teacherId: String) async throws -> [Student] {
        if shouldFailOperations {
            throw StudentServiceError.permissionDenied
        }

        return students
            .filter { $0.teacherId == teacherId && $0.isActive }
            .sorted { $0.name < $1.name }
    }

    func isStudentAllowed(nis: String, examId: String) async throws -> Bool {
        if shouldFailOperations {
            throw StudentServiceError.permissionDenied
        }

        guard let examParticipants = participants[examId] else {
            return false
        }

        return examParticipants.contains { $0.nis == nis && $0.allowed }
    }

    func searchStudents(query: String, teacherId: String) async throws -> [Student] {
        if shouldFailOperations {
            throw StudentServiceError.permissionDenied
        }

        let allStudents = try await listStudents(forTeacher: teacherId)
        return allStudents.filter { $0.matches(query: query) }
    }

    func isNISUnique(_ nis: String, teacherId: String) async throws -> Bool {
        if shouldFailOperations {
            throw StudentServiceError.permissionDenied
        }

        let existing = try await getStudent(byNIS: nis, teacherId: teacherId)
        return existing == nil
    }
}
