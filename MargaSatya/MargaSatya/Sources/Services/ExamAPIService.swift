//
//  ExamAPIService.swift
//  MargaSatya
//
//  Production API service for exam operations
//

import Foundation

/// Production implementation of ExamAPIServiceProtocol
final class ExamAPIService: ExamAPIServiceProtocol {
    // MARK: - Properties

    private let baseURL: String
    private let session: URLSession
    private let timeout: TimeInterval

    // MARK: - Initialization

    init(
        baseURL: String = AppConfiguration.API.baseURL,
        session: URLSession = .shared,
        timeout: TimeInterval = AppConfiguration.API.timeout
    ) {
        self.baseURL = baseURL
        self.session = session
        self.timeout = timeout
    }

    // MARK: - ExamAPIServiceProtocol

    func resolveExamCode(_ code: String) async throws -> ExamResponse {
        guard let url = URL(string: "\(baseURL)\(AppConfiguration.API.Endpoints.resolveExamCode)") else {
            throw ExamAPIError.invalidURL
        }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ExamCodeRequest(code: code)
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await session.data(for: request)

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
}

// MARK: - Mock API Service

/// Mock implementation for development/testing
final class MockExamAPIService: ExamAPIServiceProtocol {
    private let mockDelay: UInt64

    init(mockDelay: UInt64 = 1_000_000_000) { // 1 second default
        self.mockDelay = mockDelay
    }

    func resolveExamCode(_ code: String) async throws -> ExamResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: mockDelay)

        // Validate code format
        guard !code.isEmpty, code.count >= AppConfiguration.UI.minExamCodeLength else {
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
