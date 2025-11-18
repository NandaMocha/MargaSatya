//
//  StudentFormViewModel.swift
//  MargaSatya
//
//  ViewModel for creating and editing students with validation
//

import SwiftUI

@MainActor
final class StudentFormViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var name: String = ""
    @Published var nis: String = ""
    @Published var isActive: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var isSaved: Bool = false

    // MARK: - Private Properties

    private let studentService: StudentServiceProtocol
    private let teacherId: String
    private let studentToEdit: Student?

    // MARK: - Computed Properties

    var isEditMode: Bool {
        studentToEdit != nil
    }

    var title: String {
        isEditMode ? "Edit Siswa" : "Tambah Siswa"
    }

    var saveButtonTitle: String {
        isEditMode ? "Simpan Perubahan" : "Tambah Siswa"
    }

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !nis.trimmingCharacters(in: .whitespaces).isEmpty &&
        isNISFormatValid
    }

    private var isNISFormatValid: Bool {
        let trimmedNIS = nis.trimmingCharacters(in: .whitespaces)
        // NIS should be numeric and typically 8-10 digits
        return trimmedNIS.count >= 4 &&
               trimmedNIS.count <= 20 &&
               trimmedNIS.allSatisfy { $0.isNumber || $0.isLetter }
    }

    var nameError: String? {
        guard !name.isEmpty else { return nil }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if trimmedName.isEmpty {
            return "Nama tidak boleh kosong"
        }
        if trimmedName.count < 3 {
            return "Nama minimal 3 karakter"
        }
        return nil
    }

    var nisError: String? {
        guard !nis.isEmpty else { return nil }
        let trimmedNIS = nis.trimmingCharacters(in: .whitespaces)
        if trimmedNIS.isEmpty {
            return "NIS tidak boleh kosong"
        }
        if trimmedNIS.count < 4 {
            return "NIS minimal 4 karakter"
        }
        if trimmedNIS.count > 20 {
            return "NIS maksimal 20 karakter"
        }
        if !trimmedNIS.allSatisfy({ $0.isNumber || $0.isLetter }) {
            return "NIS hanya boleh mengandung huruf dan angka"
        }
        return nil
    }

    // MARK: - Initialization

    init(studentService: StudentServiceProtocol, teacherId: String, studentToEdit: Student?) {
        self.studentService = studentService
        self.teacherId = teacherId
        self.studentToEdit = studentToEdit

        // Populate fields if editing
        if let student = studentToEdit {
            self.name = student.name
            self.nis = student.nis
            self.isActive = student.isActive
        }
    }

    // MARK: - Public Methods

    func save() async {
        guard isFormValid else {
            errorMessage = "Mohon lengkapi semua field dengan benar"
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let trimmedName = name.trimmingCharacters(in: .whitespaces)
            let trimmedNIS = nis.trimmingCharacters(in: .whitespaces)

            if isEditMode {
                // Update existing student
                guard var studentToUpdate = studentToEdit else {
                    throw StudentServiceError.studentNotFound
                }

                studentToUpdate.name = trimmedName
                studentToUpdate.nis = trimmedNIS
                studentToUpdate.isActive = isActive

                try await studentService.updateStudent(studentToUpdate)
            } else {
                // Check for duplicate NIS
                let existingStudent = try await studentService.getStudent(
                    byNIS: trimmedNIS,
                    teacherId: teacherId
                )

                if existingStudent != nil {
                    throw StudentServiceError.duplicateNIS
                }

                // Create new student
                let newStudent = Student(
                    name: trimmedName,
                    nis: trimmedNIS,
                    teacherId: teacherId,
                    isActive: isActive
                )

                try await studentService.createStudent(newStudent)
            }

            isSaved = true
        } catch StudentServiceError.duplicateNIS {
            errorMessage = "NIS \(nis) sudah terdaftar"
            showError = true
        } catch StudentServiceError.studentNotFound {
            errorMessage = "Siswa tidak ditemukan"
            showError = true
        } catch StudentServiceError.invalidNIS {
            errorMessage = "Format NIS tidak valid"
            showError = true
        } catch {
            errorMessage = "Gagal menyimpan data siswa: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func clearForm() {
        name = ""
        nis = ""
        isActive = true
        errorMessage = nil
        showError = false
    }
}
