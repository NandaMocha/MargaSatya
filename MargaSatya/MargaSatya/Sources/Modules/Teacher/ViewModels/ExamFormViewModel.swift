//
//  ExamFormViewModel.swift
//  MargaSatya
//
//  ViewModel for creating and editing exams (both types)
//

import SwiftUI

@MainActor
final class ExamFormViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var examType: ExamType = .googleForm
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var accessCode: String = ""
    @Published var formUrl: String = ""
    @Published var durationMinutes: String = ""
    @Published var startDate: Date = Date()
    @Published var startTime: Date = Date()
    @Published var endDate: Date = Date()
    @Published var endTime: Date = Date()
    @Published var hasTimeLimit: Bool = false
    @Published var isActive: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var isSaved: Bool = false

    // MARK: - Private Properties

    private let examService: ExamServiceProtocol
    private let teacherId: String
    private let examToEdit: Exam?

    // MARK: - Computed Properties

    var isEditMode: Bool {
        examToEdit != nil
    }

    var formTitle: String {
        isEditMode ? "Edit Ujian" : "Buat Ujian Baru"
    }

    var saveButtonTitle: String {
        isEditMode ? "Simpan Perubahan" : "Buat Ujian"
    }

    var isFormValid: Bool {
        let basicValid = !title.trimmingCharacters(in: .whitespaces).isEmpty &&
                        !accessCode.trimmingCharacters(in: .whitespaces).isEmpty

        switch examType {
        case .googleForm:
            return basicValid && isUrlValid(formUrl)
        case .inApp:
            return basicValid
        }
    }

    var titleError: String? {
        guard !title.isEmpty else { return nil }
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return "Judul tidak boleh kosong"
        }
        if trimmed.count < 3 {
            return "Judul minimal 3 karakter"
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
        if !trimmed.allSatisfy({ $0.isLetter || $0.isNumber }) {
            return "Kode akses hanya boleh huruf dan angka"
        }
        return nil
    }

    var formUrlError: String? {
        guard examType == .googleForm, !formUrl.isEmpty else { return nil }
        if !isUrlValid(formUrl) {
            return "URL Google Form tidak valid"
        }
        return nil
    }

    var durationError: String? {
        guard !durationMinutes.isEmpty else { return nil }
        if let duration = Int(durationMinutes) {
            if duration < 1 {
                return "Durasi minimal 1 menit"
            }
            if duration > 480 {
                return "Durasi maksimal 480 menit (8 jam)"
            }
        } else {
            return "Durasi harus berupa angka"
        }
        return nil
    }

    var timeRangeError: String? {
        guard hasTimeLimit else { return nil }

        let start = combineDateAndTime(date: startDate, time: startTime)
        let end = combineDateAndTime(date: endDate, time: endTime)

        if end <= start {
            return "Waktu selesai harus setelah waktu mulai"
        }

        return nil
    }

    // MARK: - Initialization

    init(examService: ExamServiceProtocol, teacherId: String, examToEdit: Exam?) {
        self.examService = examService
        self.teacherId = teacherId
        self.examToEdit = examToEdit

        // Populate fields if editing
        if let exam = examToEdit {
            self.examType = exam.type
            self.title = exam.title
            self.description = exam.description ?? ""
            self.accessCode = exam.accessCode
            self.formUrl = exam.formUrl ?? ""
            self.durationMinutes = exam.durationMinutes.map { String($0) } ?? ""
            self.isActive = exam.isActive

            if let startTime = exam.startTime, let endTime = exam.endTime {
                self.hasTimeLimit = true
                self.startDate = startTime
                self.startTime = startTime
                self.endDate = endTime
                self.endTime = endTime
            }
        } else {
            // Generate random access code for new exams
            self.accessCode = generateAccessCode()
        }
    }

    // MARK: - Public Methods

    func save() async {
        guard isFormValid else {
            errorMessage = "Mohon lengkapi semua field dengan benar"
            showError = true
            return
        }

        if let timeError = timeRangeError {
            errorMessage = timeError
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
            let trimmedDescription = description.trimmingCharacters(in: .whitespaces)
            let trimmedAccessCode = accessCode.trimmingCharacters(in: .whitespaces).uppercased()

            var exam: Exam

            if isEditMode {
                // Update existing exam
                guard var examToUpdate = examToEdit else {
                    throw ExamServiceError.examNotFound
                }

                examToUpdate.title = trimmedTitle
                examToUpdate.description = trimmedDescription.isEmpty ? nil : trimmedDescription
                examToUpdate.accessCode = trimmedAccessCode
                examToUpdate.durationMinutes = Int(durationMinutes)
                examToUpdate.isActive = isActive

                if examType == .googleForm {
                    examToUpdate.formUrl = formUrl.trimmingCharacters(in: .whitespaces)
                }

                if hasTimeLimit {
                    examToUpdate.startTime = combineDateAndTime(date: startDate, time: startTime)
                    examToUpdate.endTime = combineDateAndTime(date: endDate, time: endTime)
                } else {
                    examToUpdate.startTime = nil
                    examToUpdate.endTime = nil
                }

                exam = try await examService.updateExam(examToUpdate)
            } else {
                // Create new exam
                var newExam = Exam(
                    type: examType,
                    title: trimmedTitle,
                    description: trimmedDescription.isEmpty ? nil : trimmedDescription,
                    accessCode: trimmedAccessCode,
                    teacherId: teacherId,
                    formUrl: examType == .googleForm ? formUrl.trimmingCharacters(in: .whitespaces) : nil,
                    durationMinutes: Int(durationMinutes),
                    isActive: isActive
                )

                if hasTimeLimit {
                    newExam.startTime = combineDateAndTime(date: startDate, time: startTime)
                    newExam.endTime = combineDateAndTime(date: endDate, time: endTime)
                }

                exam = try await examService.createExam(newExam)
            }

            isSaved = true
        } catch ExamServiceError.examNotFound {
            errorMessage = "Ujian tidak ditemukan"
            showError = true
        } catch ExamServiceError.invalidFormUrl {
            errorMessage = "URL Google Form tidak valid"
            showError = true
        } catch {
            errorMessage = "Gagal menyimpan ujian: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func regenerateAccessCode() {
        accessCode = generateAccessCode()
    }

    // MARK: - Private Methods

    private func isUrlValid(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme == "https" && url.host?.contains("google.com") == true
    }

    private func generateAccessCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Exclude similar chars
        return String((0..<6).map { _ in characters.randomElement()! })
    }

    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        return calendar.date(from: combined) ?? date
    }
}
