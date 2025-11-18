//
//  Student.swift
//  MargaSatya
//
//  Student model for exam participants
//

import Foundation
import FirebaseFirestore

// MARK: - Student Model

struct Student: Codable, Identifiable {
    @DocumentID var id: String?
    let teacherId: String
    let nis: String // Nomor Induk Siswa (unique per teacher)
    var name: String
    var className: String?
    var additionalInfo: String?
    var isActive: Bool
    let createdAt: Date
    var updatedAt: Date

    // MARK: - Optional Properties

    var email: String?
    var phoneNumber: String?
    var parentContact: String?

    // MARK: - Initialization

    init(
        id: String? = nil,
        teacherId: String,
        nis: String,
        name: String,
        className: String? = nil,
        additionalInfo: String? = nil,
        email: String? = nil,
        phoneNumber: String? = nil,
        parentContact: String? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.teacherId = teacherId
        self.nis = nis
        self.name = name
        self.className = className
        self.additionalInfo = additionalInfo
        self.email = email
        self.phoneNumber = phoneNumber
        self.parentContact = parentContact
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    var displayName: String {
        if let className = className, !className.isEmpty {
            return "\(name) (\(className))"
        }
        return name
    }

    var searchableText: String {
        let parts = [
            nis,
            name.lowercased(),
            className?.lowercased() ?? ""
        ]
        return parts.joined(separator: " ")
    }

    // MARK: - Methods

    mutating func updateInfo(
        name: String? = nil,
        className: String? = nil,
        additionalInfo: String? = nil
    ) {
        if let name = name {
            self.name = name
        }
        if let className = className {
            self.className = className
        }
        if let additionalInfo = additionalInfo {
            self.additionalInfo = additionalInfo
        }
        self.updatedAt = Date()
    }

    mutating func deactivate() {
        self.isActive = false
        self.updatedAt = Date()
    }

    mutating func activate() {
        self.isActive = true
        self.updatedAt = Date()
    }
}

// MARK: - Student Extensions

extension Student {
    /// Check if student matches search query
    func matches(query: String) -> Bool {
        let lowercaseQuery = query.lowercased()
        return searchableText.contains(lowercaseQuery)
    }

    /// Generate unique composite key for NIS + Teacher
    var compositeKey: String {
        return "\(teacherId)_\(nis)"
    }
}

// MARK: - Equatable & Hashable

extension Student: Equatable {
    static func == (lhs: Student, rhs: Student) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Student: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Student Statistics

struct StudentStatistics: Codable {
    let studentId: String
    let totalExamsTaken: Int
    let totalExamsCompleted: Int
    let averageCompletionTime: TimeInterval?
    let lastExamDate: Date?

    var completionRate: Double {
        guard totalExamsTaken > 0 else { return 0 }
        return Double(totalExamsCompleted) / Double(totalExamsTaken)
    }
}
