//
//  StudentEntryViewModel.swift
//  MargaSatya
//
//  ViewModel for student NIS and exam access code entry
//

import SwiftUI

@MainActor
final class StudentEntryViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var nis: String = ""
    @Published var accessCode: String = ""
    @Published var studentName: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var isAuthenticated: Bool = false
    @Published var currentExam: Exam?
    @Published var currentSession: ExamSession?

    // MARK: - Private Properties

    private let studentService: StudentServiceProtocol
    private let examService: ExamServiceProtocol
    private let sessionService: ExamSessionServiceProtocol

    // MARK: - Computed Properties

    var isNISValid: Bool {
        let trimmed = nis.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 4 && trimmed.count <= 20
    }

    var isAccessCodeValid: Bool {
        let trimmed = accessCode.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 4 && trimmed.count <= 10
    }

    var canProceed: Bool {
        isNISValid && isAccessCodeValid
    }

    var nisError: String? {
        guard !nis.isEmpty else { return nil }
        let trimmed = nis.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return "NIS tidak boleh kosong"
        }
        if trimmed.count < 4 {
            return "NIS minimal 4 karakter"
        }
        if trimmed.count > 20 {
            return "NIS maksimal 20 karakter"
        }
        return nil
    }

    var accessCodeError: String? {
        guard !accessCode.isEmpty else { return nil }
        let trimmed = accessCode.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return "Kode akses tidak boleh kosong"
        }
        if trimmed.count < 4 {
            return "Kode akses minimal 4 karakter"
        }
        if trimmed.count > 10 {
            return "Kode akses maksimal 10 karakter"
        }
        return nil
    }

    // MARK: - Initialization

    init(studentService: StudentServiceProtocol, examService: ExamServiceProtocol, sessionService: ExamSessionServiceProtocol) {
        self.studentService = studentService
        self.examService = examService
        self.sessionService = sessionService
    }

    // MARK: - Public Methods

    func validateAndProceed() async {
        guard canProceed else {
            errorMessage = "Mohon lengkapi NIS dan kode akses dengan benar"
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let trimmedNIS = nis.trimmingCharacters(in: .whitespaces)
            let trimmedCode = accessCode.trimmingCharacters(in: .whitespaces).uppercased()

            // Step 1: Find exam by access code
            guard let exam = try await examService.getExam(byAccessCode: trimmedCode) else {
                errorMessage = "Kode akses tidak valid"
                showError = true
                isLoading = false
                return
            }

            // Step 2: Check if exam is active
            guard exam.isActive else {
                errorMessage = "Ujian tidak aktif"
                showError = true
                isLoading = false
                return
            }

            // Step 3: Check exam access time
            let accessCheck = exam.canAccess()
            guard accessCheck.allowed else {
                errorMessage = accessCheck.reason ?? "Ujian tidak dapat diakses saat ini"
                showError = true
                isLoading = false
                return
            }

            // Step 4: Verify student is allowed to take this exam
            let isAllowed = try await studentService.isStudentAllowed(nis: trimmedNIS, examId: exam.id ?? "")
            guard isAllowed else {
                errorMessage = "Anda tidak terdaftar sebagai peserta ujian ini"
                showError = true
                isLoading = false
                return
            }

            // Step 5: Get student info (optional - for display purposes)
            if let student = try await studentService.getStudent(byNIS: trimmedNIS, teacherId: nil) {
                studentName = student.name
            }

            // Step 6: Check for existing session or create new one
            if let existingSession = try await sessionService.getSession(forExamId: exam.id ?? "", studentNIS: trimmedNIS) {
                // Resume existing session
                if existingSession.status == .submitted {
                    errorMessage = "Anda sudah menyelesaikan ujian ini"
                    showError = true
                    isLoading = false
                    return
                }
                currentSession = existingSession
            } else {
                // Create new session
                var newSession = ExamSession(
                    examId: exam.id ?? "",
                    studentId: nil, // Students don't have user accounts
                    nis: trimmedNIS,
                    status: .notStarted
                )

                currentSession = try await sessionService.createSession(newSession)
            }

            currentExam = exam
            isAuthenticated = true

        } catch StudentServiceError.studentNotFound {
            errorMessage = "NIS tidak ditemukan"
            showError = true
        } catch {
            errorMessage = "Gagal memvalidasi: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func clearForm() {
        nis = ""
        accessCode = ""
        studentName = ""
        errorMessage = nil
        showError = false
        isAuthenticated = false
        currentExam = nil
        currentSession = nil
    }
}
