//
//  ExamParticipant.swift
//  MargaSatya
//
//  Model for students allowed to take a specific exam
//

import Foundation
import FirebaseFirestore

// MARK: - Exam Participant Model

struct ExamParticipant: Codable, Identifiable {
    @DocumentID var id: String?
    let studentId: String
    let nis: String // Cached for quick lookup
    var studentName: String // Cached for display
    var allowed: Bool // Permission to take exam
    let createdAt: Date
    var updatedAt: Date

    // MARK: - Additional Properties

    var notes: String? // Teacher notes about this participant

    // MARK: - Initialization

    init(
        id: String? = nil,
        studentId: String,
        nis: String,
        studentName: String,
        allowed: Bool = true,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.studentId = studentId
        self.nis = nis
        self.studentName = studentName
        self.allowed = allowed
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Convenience Init from Student

    init(from student: Student, allowed: Bool = true) {
        self.id = nil
        self.studentId = student.id ?? ""
        self.nis = student.nis
        self.studentName = student.name
        self.allowed = allowed
        self.notes = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Methods

    mutating func allow() {
        self.allowed = true
        self.updatedAt = Date()
    }

    mutating func deny() {
        self.allowed = false
        self.updatedAt = Date()
    }

    mutating func updateNotes(_ notes: String?) {
        self.notes = notes
        self.updatedAt = Date()
    }

    mutating func updateStudentInfo(name: String) {
        self.studentName = name
        self.updatedAt = Date()
    }
}

// MARK: - Equatable & Hashable

extension ExamParticipant: Equatable {
    static func == (lhs: ExamParticipant, rhs: ExamParticipant) -> Bool {
        return lhs.studentId == rhs.studentId
    }
}

extension ExamParticipant: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(studentId)
    }
}
