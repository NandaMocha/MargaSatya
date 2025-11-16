//
//  ExamAPIServiceProtocol.swift
//  MargaSatya
//
//  Protocol for exam API service abstraction
//

import Foundation

/// Protocol defining exam API operations
protocol ExamAPIServiceProtocol {
    /// Validate exam code and retrieve exam configuration
    /// - Parameter code: The exam code to validate
    /// - Returns: ExamResponse containing exam details
    /// - Throws: ExamAPIError if validation fails
    func resolveExamCode(_ code: String) async throws -> ExamResponse
}
