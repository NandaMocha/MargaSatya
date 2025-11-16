//
//  ExamResponse.swift
//  MargaSatya
//
//  Secure Exam Browser - iOS
//

import Foundation

/// Response model from exam code validation API
struct ExamResponse: Codable {
    let examId: String
    let examUrl: String
    let examTitle: String
    let duration: Int // in minutes
    let lockMode: Bool
}

/// Request model for exam code validation
struct ExamCodeRequest: Codable {
    let code: String
}
