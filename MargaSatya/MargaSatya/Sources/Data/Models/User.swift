//
//  User.swift
//  SecureExamID
//
//  User model for authentication and role-based access
//

import Foundation
import FirebaseFirestore

// MARK: - User Role

enum UserRole: String, Codable {
    case admin = "ADMIN"
    case teacher = "GURU"
    case student = "SISWA" // Optional, siswa tidak perlu auth tapi bisa dibuat account
}

// MARK: - User Model

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String
    let email: String
    let role: UserRole
    let createdAt: Date
    var updatedAt: Date
    var isActive: Bool

    // MARK: - Additional Properties

    /// Firebase Auth UID (untuk link dengan Authentication)
    var authUID: String?

    /// Profile photo URL (optional)
    var photoURL: String?

    /// Phone number (optional)
    var phoneNumber: String?

    // MARK: - Initialization

    init(
        id: String? = nil,
        name: String,
        email: String,
        role: UserRole,
        authUID: String? = nil,
        photoURL: String? = nil,
        phoneNumber: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
        self.authUID = authUID
        self.photoURL = photoURL
        self.phoneNumber = phoneNumber
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isActive = isActive
    }

    // MARK: - Computed Properties

    var displayName: String {
        return name
    }

    var roleDisplayName: String {
        switch role {
        case .admin:
            return "Administrator"
        case .teacher:
            return "Guru"
        case .student:
            return "Siswa"
        }
    }

    var isAdmin: Bool {
        return role == .admin
    }

    var isTeacher: Bool {
        return role == .teacher
    }

    var isStudent: Bool {
        return role == .student
    }

    // MARK: - Methods

    mutating func updateLastActivity() {
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

// MARK: - User Extensions

extension User {
    /// Check if user has permission for specific action
    func hasPermission(for action: UserAction) -> Bool {
        switch action {
        case .manageStudents:
            return role == .teacher || role == .admin
        case .createExams:
            return role == .teacher || role == .admin
        case .viewAllExams:
            return role == .admin
        case .manageAppConfig:
            return role == .admin
        case .viewStatistics:
            return role == .admin || role == .teacher
        case .takeExam:
            return true // Semua bisa, termasuk non-authenticated students
        }
    }
}

// MARK: - User Actions

enum UserAction {
    case manageStudents
    case createExams
    case viewAllExams
    case manageAppConfig
    case viewStatistics
    case takeExam
}

// MARK: - User DTO (for API responses)

struct UserDTO: Codable {
    let id: String
    let name: String
    let email: String
    let role: String
    let photoURL: String?

    init(from user: User) {
        self.id = user.id ?? ""
        self.name = user.name
        self.email = user.email
        self.role = user.role.rawValue
        self.photoURL = user.photoURL
    }
}

// MARK: - Equatable & Hashable

extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}

extension User: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
