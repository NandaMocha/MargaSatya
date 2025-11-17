//
//  ExamListViewModel.swift
//  SecureExamID
//
//  ViewModel for managing exam list with filtering and search
//

import SwiftUI
import Combine

@MainActor
final class ExamListViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var exams: [Exam] = []
    @Published var filteredExams: [Exam] = []
    @Published var searchText: String = ""
    @Published var selectedTypeFilter: ExamTypeFilter = .all
    @Published var selectedStatusFilter: ExamStatusFilter = .all
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // MARK: - Private Properties

    private let examService: ExamServiceProtocol
    private let teacherId: String
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Enums

    enum ExamTypeFilter: String, CaseIterable {
        case all = "Semua"
        case googleForm = "Google Form"
        case inApp = "In-App"

        var examType: ExamType? {
            switch self {
            case .all: return nil
            case .googleForm: return .googleForm
            case .inApp: return .inApp
            }
        }
    }

    enum ExamStatusFilter: String, CaseIterable {
        case all = "Semua"
        case ready = "Siap"
        case scheduled = "Terjadwal"
        case running = "Berlangsung"
        case finished = "Selesai"

        var examStatus: ExamStatus? {
            switch self {
            case .all: return nil
            case .ready: return .ready
            case .scheduled: return .scheduled
            case .running: return .running
            case .finished: return .finished
            }
        }
    }

    // MARK: - Computed Properties

    var examsToDisplay: [Exam] {
        searchText.isEmpty && selectedTypeFilter == .all && selectedStatusFilter == .all
            ? exams
            : filteredExams
    }

    var hasExams: Bool {
        !exams.isEmpty
    }

    var examCount: Int {
        exams.count
    }

    var activeExamCount: Int {
        exams.filter { $0.status == .running }.count
    }

    // MARK: - Initialization

    init(examService: ExamServiceProtocol, teacherId: String) {
        self.examService = examService
        self.teacherId = teacherId

        setupSearchObserver()
        setupFilterObservers()
    }

    // MARK: - Public Methods

    func loadExams() async {
        isLoading = true
        errorMessage = nil

        do {
            exams = try await examService.getExams(forTeacherId: teacherId)
            exams.sort { exam1, exam2 in
                // Sort by status priority, then by start time
                if exam1.status != exam2.status {
                    return exam1.status.sortPriority < exam2.status.sortPriority
                }
                if let start1 = exam1.startTime, let start2 = exam2.startTime {
                    return start1 > start2 // Newest first
                }
                return exam1.title < exam2.title
            }
            applyFilters()
        } catch {
            errorMessage = "Gagal memuat data ujian: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func deleteExam(_ exam: Exam) async {
        guard let examId = exam.id else {
            errorMessage = "ID ujian tidak valid"
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await examService.deleteExam(id: examId)

            // Remove from local arrays
            exams.removeAll { $0.id == examId }
            filteredExams.removeAll { $0.id == examId }
        } catch {
            errorMessage = "Gagal menghapus ujian: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func duplicateExam(_ exam: Exam) async {
        isLoading = true
        errorMessage = nil

        do {
            var newExam = exam
            newExam.id = nil // Clear ID to create new
            newExam.title = "\(exam.title) (Salinan)"
            newExam.accessCode = generateAccessCode() // New access code
            newExam.startTime = nil
            newExam.endTime = nil
            newExam.isActive = false

            let createdExam = try await examService.createExam(newExam)

            // If In-App exam, duplicate questions
            if exam.type == .inApp, let examId = exam.id, let newExamId = createdExam.id {
                let questions = try await examService.getQuestions(forExamId: examId)
                try await examService.saveQuestions(questions, forExamId: newExamId)
            }

            await loadExams() // Reload list
        } catch {
            errorMessage = "Gagal menduplikasi ujian: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func refresh() async {
        await loadExams()
    }

    // MARK: - Private Methods

    private func setupSearchObserver() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }

    private func setupFilterObservers() {
        Publishers.CombineLatest($selectedTypeFilter, $selectedStatusFilter)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }

    private func applyFilters() {
        var result = exams

        // Apply type filter
        if let examType = selectedTypeFilter.examType {
            result = result.filter { $0.type == examType }
        }

        // Apply status filter
        if let examStatus = selectedStatusFilter.examStatus {
            result = result.filter { $0.status == examStatus }
        }

        // Apply search
        if !searchText.isEmpty {
            let lowercasedQuery = searchText.lowercased()
            result = result.filter { exam in
                exam.title.lowercased().contains(lowercasedQuery) ||
                exam.description?.lowercased().contains(lowercasedQuery) == true ||
                exam.accessCode.lowercased().contains(lowercasedQuery)
            }
        }

        filteredExams = result
    }

    private func generateAccessCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Exclude similar chars
        return String((0..<6).map { _ in characters.randomElement()! })
    }
}

// MARK: - ExamStatus Extension

extension ExamStatus {
    var sortPriority: Int {
        switch self {
        case .running: return 0
        case .scheduled: return 1
        case .ready: return 2
        case .finished: return 3
        case .inactive: return 4
        }
    }
}
