//
//  StudentListViewModel.swift
//  MargaSatya
//
//  ViewModel for managing student list with search and CRUD operations
//

import SwiftUI
import Combine

@MainActor
final class StudentListViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var students: [Student] = []
    @Published var filteredStudents: [Student] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // MARK: - Private Properties

    private let studentService: StudentServiceProtocol
    private let teacherId: String
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var studentsToDisplay: [Student] {
        searchText.isEmpty ? students : filteredStudents
    }

    var hasStudents: Bool {
        !students.isEmpty
    }

    var studentCount: Int {
        students.count
    }

    // MARK: - Initialization

    init(studentService: StudentServiceProtocol, teacherId: String) {
        self.studentService = studentService
        self.teacherId = teacherId

        setupSearchObserver()
    }

    // MARK: - Public Methods

    func loadStudents() async {
        isLoading = true
        errorMessage = nil

        do {
            students = try await studentService.getStudents(forTeacherId: teacherId)
            students.sort { $0.nis < $1.nis } // Sort by NIS
        } catch {
            errorMessage = "Gagal memuat data siswa: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func deleteStudent(_ student: Student) async {
        guard let studentId = student.id else {
            errorMessage = "ID siswa tidak valid"
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await studentService.deleteStudent(id: studentId)

            // Remove from local array
            students.removeAll { $0.id == studentId }

            // Also remove from filtered if present
            if !searchText.isEmpty {
                filteredStudents.removeAll { $0.id == studentId }
            }
        } catch {
            errorMessage = "Gagal menghapus siswa: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func refresh() async {
        await loadStudents()
    }

    // MARK: - Private Methods

    private func setupSearchObserver() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] searchText in
                self?.performSearch(searchText)
            }
            .store(in: &cancellables)
    }

    private func performSearch(_ query: String) {
        guard !query.isEmpty else {
            filteredStudents = []
            return
        }

        let lowercasedQuery = query.lowercased()

        filteredStudents = students.filter { student in
            student.name.lowercased().contains(lowercasedQuery) ||
            student.nis.lowercased().contains(lowercasedQuery)
        }
    }
}
