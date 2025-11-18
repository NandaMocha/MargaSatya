//
//  StudentServiceProtocol.swift
//  MargaSatya
//
//  Protocol for student management operations
//

import Foundation

// MARK: - Student Service Protocol

protocol StudentServiceProtocol {
    /// Get student by NIS (Nomor Induk Siswa)
    func getStudent(byNIS nis: String, teacherId: String?) async throws -> Student?

    /// Get student by ID
    func getStudent(byId id: String) async throws -> Student?

    /// Create new student
    func createStudent(_ student: StudentDraft, teacherId: String) async throws -> Student

    /// Update student
    func updateStudent(_ student: Student) async throws

    /// Delete student (soft delete)
    func deleteStudent(studentId: String) async throws

    /// List all students for a teacher
    func listStudents(forTeacher teacherId: String) async throws -> [Student]

    /// List active students only
    func listActiveStudents(forTeacher teacherId: String) async throws -> [Student]

    /// Check if student is allowed to take specific exam
    func isStudentAllowed(nis: String, examId: String) async throws -> Bool

    /// Search students by name or NIS
    func searchStudents(
        query: String,
        teacherId: String
    ) async throws -> [Student]

    /// Check if NIS is unique for a teacher
    func isNISUnique(_ nis: String, teacherId: String) async throws -> Bool
}

// MARK: - Student Draft (for creation)

struct StudentDraft {
    let nis: String
    let name: String
    let className: String?
    let additionalInfo: String?
}
