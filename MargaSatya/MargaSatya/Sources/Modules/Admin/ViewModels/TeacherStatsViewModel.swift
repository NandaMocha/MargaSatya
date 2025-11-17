//
//  TeacherStatsViewModel.swift
//  SecureExamID
//
//  ViewModel for teacher statistics
//

import SwiftUI

@MainActor
final class TeacherStatsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var stats: TeacherStats?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // MARK: - Private Properties

    private let adminService: AdminServiceProtocol
    private let teacherId: String

    // MARK: - Computed Properties

    var hasStats: Bool {
        stats != nil
    }

    var totalStudents: Int {
        stats?.totalStudents ?? 0
    }

    var totalExams: Int {
        stats?.totalExams ?? 0
    }

    var totalSessions: Int {
        stats?.totalSessions ?? 0
    }

    var activeExams: Int {
        stats?.activeExams ?? 0
    }

    // MARK: - Initialization

    init(adminService: AdminServiceProtocol, teacherId: String) {
        self.adminService = adminService
        self.teacherId = teacherId
    }

    // MARK: - Public Methods

    func loadStats() async {
        isLoading = true
        errorMessage = nil

        do {
            stats = try await adminService.getTeacherStats(teacherId: teacherId)
        } catch {
            errorMessage = "Gagal memuat statistik guru: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func refresh() async {
        await loadStats()
    }
}
