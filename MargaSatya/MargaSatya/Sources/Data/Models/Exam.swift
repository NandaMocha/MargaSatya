//
//  Exam.swift
//  MargaSatya
//
//  Exam model supporting Google Form and In-App exams
//

import Foundation
import FirebaseFirestore

// MARK: - Exam Type

enum ExamType: String, Codable {
    case googleForm = "GOOGLE_FORM"
    case inApp = "IN_APP"

    var displayName: String {
        switch self {
        case .googleForm:
            return "Google Form"
        case .inApp:
            return "Ujian In-App"
        }
    }
}

// MARK: - Exam Model

struct Exam: Codable, Identifiable {
    @DocumentID var id: String?
    let teacherId: String
    var title: String
    var description: String
    let examCode: String // Unique code for students to access
    let type: ExamType
    var formUrl: String? // Only for GOOGLE_FORM type
    var startTime: Date?
    var endTime: Date?
    var durationMinutes: Int?
    var isActive: Bool
    let createdAt: Date
    var updatedAt: Date

    // MARK: - Additional Settings

    var lockMode: Bool // Use AAC (Assessment Mode)
    var shuffleQuestions: Bool // For IN_APP exams
    var shuffleOptions: Bool // For IN_APP multiple choice
    var showResults: Bool // Show results after submission
    var allowReview: Bool // Allow reviewing answers after submit

    // MARK: - Metadata

    var totalQuestions: Int? // Cached from subcollection
    var totalParticipants: Int? // Cached from subcollection

    // MARK: - Initialization

    init(
        id: String? = nil,
        teacherId: String,
        title: String,
        description: String,
        examCode: String,
        type: ExamType,
        formUrl: String? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        durationMinutes: Int? = nil,
        lockMode: Bool = true,
        shuffleQuestions: Bool = false,
        shuffleOptions: Bool = false,
        showResults: Bool = false,
        allowReview: Bool = false,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.teacherId = teacherId
        self.title = title
        self.description = description
        self.examCode = examCode
        self.type = type
        self.formUrl = formUrl
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.lockMode = lockMode
        self.shuffleQuestions = shuffleQuestions
        self.shuffleOptions = shuffleOptions
        self.showResults = showResults
        self.allowReview = allowReview
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.totalQuestions = nil
        self.totalParticipants = nil
    }

    // MARK: - Computed Properties

    var status: ExamStatus {
        let now = Date()

        // Check if exam is inactive
        guard isActive else {
            return .inactive
        }

        // If no time constraints, consider as ready
        guard let startTime = startTime, let endTime = endTime else {
            return .ready
        }

        if now < startTime {
            return .scheduled
        } else if now >= startTime && now <= endTime {
            return .running
        } else {
            return .finished
        }
    }

    var statusDisplayName: String {
        return status.displayName
    }

    var typeDisplayName: String {
        return type.displayName
    }

    var durationDisplay: String {
        guard let duration = durationMinutes else {
            return "Tidak dibatasi"
        }

        if duration >= 60 {
            let hours = duration / 60
            let minutes = duration % 60
            if minutes > 0 {
                return "\(hours) jam \(minutes) menit"
            } else {
                return "\(hours) jam"
            }
        } else {
            return "\(duration) menit"
        }
    }

    var timeRangeDisplay: String {
        guard let start = startTime, let end = endTime else {
            return "Belum dijadwalkan"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        formatter.locale = Locale(identifier: "id_ID")

        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    var isGoogleForm: Bool {
        return type == .googleForm
    }

    var isInApp: Bool {
        return type == .inApp
    }

    // MARK: - Validation

    var isValid: Bool {
        // Basic validation
        guard !title.isEmpty, !examCode.isEmpty else {
            return false
        }

        // Type-specific validation
        switch type {
        case .googleForm:
            guard let url = formUrl, !url.isEmpty else {
                return false
            }
            return URL(string: url) != nil

        case .inApp:
            // In-app exams need questions (checked separately)
            return true
        }
    }

    var validationErrors: [String] {
        var errors: [String] = []

        if title.isEmpty {
            errors.append("Judul ujian tidak boleh kosong")
        }

        if examCode.isEmpty {
            errors.append("Kode ujian tidak boleh kosong")
        }

        if type == .googleForm {
            if formUrl == nil || formUrl?.isEmpty == true {
                errors.append("URL Google Form harus diisi")
            } else if let url = formUrl, URL(string: url) == nil {
                errors.append("URL Google Form tidak valid")
            }
        }

        if let start = startTime, let end = endTime, start >= end {
            errors.append("Waktu mulai harus sebelum waktu selesai")
        }

        return errors
    }

    // MARK: - Methods

    mutating func updateMetadata(questions: Int, participants: Int) {
        self.totalQuestions = questions
        self.totalParticipants = participants
        self.updatedAt = Date()
    }

    mutating func activate() {
        self.isActive = true
        self.updatedAt = Date()
    }

    mutating func deactivate() {
        self.isActive = false
        self.updatedAt = Date()
    }

    /// Check if student can access this exam now
    func canAccess(at date: Date = Date()) -> (allowed: Bool, reason: String?) {
        // Check if exam is active
        guard isActive else {
            return (false, "Ujian tidak aktif")
        }

        // Check validation
        guard isValid else {
            return (false, "Ujian belum dikonfigurasi dengan benar")
        }

        // Check time constraints
        if let startTime = startTime, date < startTime {
            return (false, "Ujian belum dimulai")
        }

        if let endTime = endTime, date > endTime {
            return (false, "Ujian sudah berakhir")
        }

        return (true, nil)
    }
}

// MARK: - Exam Status

enum ExamStatus: String, Codable {
    case scheduled = "SCHEDULED" // Belum dimulai
    case ready = "READY" // Siap tapi belum ada waktu
    case running = "RUNNING" // Sedang berlangsung
    case finished = "FINISHED" // Sudah selesai
    case inactive = "INACTIVE" // Tidak aktif

    var displayName: String {
        switch self {
        case .scheduled:
            return "Terjadwal"
        case .ready:
            return "Siap"
        case .running:
            return "Berlangsung"
        case .finished:
            return "Selesai"
        case .inactive:
            return "Tidak Aktif"
        }
    }

    var color: String {
        switch self {
        case .scheduled:
            return "blue"
        case .ready:
            return "green"
        case .running:
            return "orange"
        case .finished:
            return "gray"
        case .inactive:
            return "red"
        }
    }
}

// MARK: - Equatable & Hashable

extension Exam: Equatable {
    static func == (lhs: Exam, rhs: Exam) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Exam: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
