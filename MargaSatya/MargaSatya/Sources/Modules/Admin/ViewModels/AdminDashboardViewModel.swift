//
//  AdminDashboardViewModel.swift
//  SecureExamID
//
//  ViewModel for admin dashboard with statistics
//

import SwiftUI

@MainActor
final class AdminDashboardViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var summary: AdminSummary?
    @Published var teachers: [User] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // MARK: - Private Properties

    private let adminService: AdminServiceProtocol
    private let authService: AuthServiceProtocol

    // MARK: - Computed Properties

    var hasSummary: Bool {
        summary != nil
    }

    var totalTeachers: Int {
        summary?.totalTeachers ?? 0
    }

    var totalStudents: Int {
        summary?.totalStudents ?? 0
    }

    var totalExams: Int {
        summary?.totalExams ?? 0
    }

    var runningExams: Int {
        summary?.runningExams ?? 0
    }

    var sessionsToday: Int {
        summary?.sessionsToday ?? 0
    }

    // MARK: - Initialization

    init(adminService: AdminServiceProtocol, authService: AuthServiceProtocol) {
        self.adminService = adminService
        self.authService = authService
    }

    // MARK: - Public Methods

    func loadDashboard() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load summary statistics
            summary = try await adminService.getSummary()

            // Load teachers list
            teachers = try await authService.getUsers(role: .teacher)
            teachers.sort { $0.name < $1.name }

        } catch {
            errorMessage = "Gagal memuat data dashboard: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func refresh() async {
        await loadDashboard()
    }

    func loadTeacherStats(teacherId: String) async throws -> TeacherStats {
        return try await adminService.getTeacherStats(teacherId: teacherId)
    }

    func loadExamAnalytics(examId: String) async throws -> ExamAnalytics {
        return try await adminService.getExamAnalytics(examId: examId)
    }
}
