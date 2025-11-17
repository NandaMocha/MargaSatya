//
//  ParticipantSelectionViewModel.swift
//  SecureExamID
//
//  ViewModel for managing exam participants
//

import SwiftUI
import Combine

@MainActor
final class ParticipantSelectionViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var allStudents: [Student] = []
    @Published var participants: [ExamParticipant] = []
    @Published var searchText: String = ""
    @Published var filteredStudents: [Student] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var isSaved: Bool = false

    // MARK: - Private Properties

    private let examService: ExamServiceProtocol
    private let studentService: StudentServiceProtocol
    private let examId: String
    private let teacherId: String
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var studentsToDisplay: [Student] {
        searchText.isEmpty ? allStudents : filteredStudents
    }

    var selectedCount: Int {
        participants.filter { $0.allowed }.count
    }

    var totalStudents: Int {
        allStudents.count
    }

    // MARK: - Initialization

    init(examService: ExamServiceProtocol, studentService: StudentServiceProtocol, examId: String, teacherId: String) {
        self.examService = examService
        self.studentService = studentService
        self.examId = examId
        self.teacherId = teacherId

        setupSearchObserver()
    }

    // MARK: - Public Methods

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load students and participants concurrently
            async let studentsTask = studentService.getStudents(forTeacherId: teacherId)
            async let participantsTask = examService.getParticipants(forExamId: examId)

            allStudents = try await studentsTask
            allStudents.sort { $0.name < $1.name }

            participants = try await participantsTask

            // Ensure all students have participant entries
            ensureAllStudentsHaveParticipants()
        } catch {
            errorMessage = "Gagal memuat data: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func toggleStudent(_ student: Student) {
        if let index = participants.firstIndex(where: { $0.nis == student.nis }) {
            participants[index].allowed.toggle()
        }
    }

    func isStudentAllowed(_ student: Student) -> Bool {
        participants.first(where: { $0.nis == student.nis })?.allowed ?? false
    }

    func selectAll() {
        for index in participants.indices {
            participants[index].allowed = true
        }
    }

    func deselectAll() {
        for index in participants.indices {
            participants[index].allowed = false
        }
    }

    func save() async {
        isLoading = true
        errorMessage = nil

        do {
            try await examService.saveParticipants(participants, forExamId: examId)
            isSaved = true
        } catch {
            errorMessage = "Gagal menyimpan peserta: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
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

        filteredStudents = allStudents.filter { student in
            student.name.lowercased().contains(lowercasedQuery) ||
            student.nis.lowercased().contains(lowercasedQuery)
        }
    }

    private func ensureAllStudentsHaveParticipants() {
        for student in allStudents {
            // Check if participant already exists
            if !participants.contains(where: { $0.nis == student.nis }) {
                // Create new participant (not allowed by default)
                let newParticipant = ExamParticipant(
                    nis: student.nis,
                    studentName: student.name,
                    allowed: false
                )
                participants.append(newParticipant)
            }
        }
    }
}
