//
//  ExamAPIService.swift
//  MargaSatya
//
//  Secure Exam Browser - iOS
//

import Foundation

/// API service for exam operations
class ExamAPIService {
    static let shared = ExamAPIService()

    // TODO: Replace with actual backend URL
    private let baseURL = "https://api.margasatya.com"

    private init() {}

    /// Validate exam code and retrieve exam configuration
    func resolveExamCode(_ code: String) async throws -> ExamResponse {
        guard let url = URL(string: "\(baseURL)/exam/resolve-code") else {
            throw ExamAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ExamCodeRequest(code: code)
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExamAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw ExamAPIError.invalidCode
            }
            throw ExamAPIError.serverError(statusCode: httpResponse.statusCode)
        }

        do {
            let examResponse = try JSONDecoder().decode(ExamResponse.self, from: data)
            return examResponse
        } catch {
            throw ExamAPIError.decodingError(error)
        }
    }

    // MARK: - Mock Data for Development
    /// Mock resolve exam code for testing (remove in production)
    func mockResolveExamCode(_ code: String) async throws -> ExamResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Validate code format (simple validation)
        guard !code.isEmpty, code.count >= 3 else {
            throw ExamAPIError.invalidCode
        }

        // Return mock data
        return ExamResponse(
            examId: "EX001",
            examUrl: "https://docs.google.com/forms/d/e/1FAIpQLSc_EXAMPLE/viewform",
            examTitle: "Ujian Akhir Semester",
            duration: 60,
            lockMode: true
        )
    }
}

// MARK: - API Errors
enum ExamAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidCode
    case serverError(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid server response"
        case .invalidCode:
            return "Invalid exam code. Please check and try again."
        case .serverError(let statusCode):
            return "Server error (Code: \(statusCode))"
        case .decodingError:
            return "Failed to decode server response"
        case .networkError:
            return "Network connection error"
        }
    }
}
