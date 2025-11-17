//
//  StudentModelTests.swift
//  MargaSatyaTests
//
//  Unit tests for Student model
//

import Testing
import Foundation
@testable import MargaSatya

@Suite("Student Model Tests")
struct StudentModelTests {

    // MARK: - Initialization Tests

    @Test("Student initialization with required fields")
    func testStudentInitialization() {
        let student = Student(
            teacherId: "teacher123",
            nis: "12345",
            name: "Ahmad Suryadi"
        )

        #expect(student.teacherId == "teacher123")
        #expect(student.nis == "12345")
        #expect(student.name == "Ahmad Suryadi")
        #expect(student.isActive == true)
        #expect(student.className == nil)
    }

    @Test("Student initialization with all fields")
    func testStudentFullInitialization() {
        let student = Student(
            id: "student123",
            teacherId: "teacher123",
            nis: "12345",
            name: "Ahmad Suryadi",
            className: "XII IPA 1",
            additionalInfo: "Ketua kelas",
            email: "ahmad@example.com"
        )

        #expect(student.id == "student123")
        #expect(student.className == "XII IPA 1")
        #expect(student.additionalInfo == "Ketua kelas")
        #expect(student.email == "ahmad@example.com")
    }

    // MARK: - Display Name Tests

    @Test("Display name without class")
    func testDisplayNameWithoutClass() {
        let student = Student(
            teacherId: "teacher123",
            nis: "12345",
            name: "Ahmad Suryadi"
        )

        #expect(student.displayName == "Ahmad Suryadi")
    }

    @Test("Display name with class")
    func testDisplayNameWithClass() {
        let student = Student(
            teacherId: "teacher123",
            nis: "12345",
            name: "Ahmad Suryadi",
            className: "XII IPA 1"
        )

        #expect(student.displayName == "Ahmad Suryadi (XII IPA 1)")
    }

    // MARK: - Search Tests

    @Test("Searchable text contains all relevant fields")
    func testSearchableText() {
        let student = Student(
            teacherId: "teacher123",
            nis: "12345",
            name: "Ahmad Suryadi",
            className: "XII IPA 1"
        )

        let searchText = student.searchableText
        #expect(searchText.contains("12345"))
        #expect(searchText.contains("ahmad suryadi"))
        #expect(searchText.contains("xii ipa 1"))
    }

    @Test("Student matches search query")
    func testMatchesQuery() {
        let student = Student(
            teacherId: "teacher123",
            nis: "12345",
            name: "Ahmad Suryadi",
            className: "XII IPA 1"
        )

        #expect(student.matches(query: "ahmad") == true)
        #expect(student.matches(query: "12345") == true)
        #expect(student.matches(query: "XII") == true)
        #expect(student.matches(query: "surya") == true)
        #expect(student.matches(query: "budi") == false)
    }

    // MARK: - Update Tests

    @Test("Update student info")
    func testUpdateInfo() {
        var student = Student(
            teacherId: "teacher123",
            nis: "12345",
            name: "Ahmad Suryadi"
        )

        student.updateInfo(
            name: "Ahmad Suryadi Pratama",
            className: "XII IPA 1",
            additionalInfo: "Ketua kelas"
        )

        #expect(student.name == "Ahmad Suryadi Pratama")
        #expect(student.className == "XII IPA 1")
        #expect(student.additionalInfo == "Ketua kelas")
    }

    @Test("Partial update student info")
    func testPartialUpdateInfo() {
        var student = Student(
            teacherId: "teacher123",
            nis: "12345",
            name: "Ahmad Suryadi",
            className: "XI IPA 1"
        )

        student.updateInfo(className: "XII IPA 1")

        #expect(student.name == "Ahmad Suryadi") // Unchanged
        #expect(student.className == "XII IPA 1") // Updated
    }

    // MARK: - Activation Tests

    @Test("Student activation toggle")
    func testActivationToggle() {
        var student = Student(
            teacherId: "teacher123",
            nis: "12345",
            name: "Ahmad Suryadi"
        )

        #expect(student.isActive == true)

        student.deactivate()
        #expect(student.isActive == false)

        student.activate()
        #expect(student.isActive == true)
    }

    // MARK: - Composite Key Tests

    @Test("Composite key generation")
    func testCompositeKey() {
        let student = Student(
            teacherId: "teacher123",
            nis: "12345",
            name: "Ahmad Suryadi"
        )

        #expect(student.compositeKey == "teacher123_12345")
    }

    // MARK: - Equatable Tests

    @Test("Student equality based on ID")
    func testStudentEquality() {
        let student1 = Student(
            id: "student1",
            teacherId: "teacher123",
            nis: "12345",
            name: "Ahmad"
        )
        let student2 = Student(
            id: "student1",
            teacherId: "teacher456",
            nis: "67890",
            name: "Budi"
        )
        let student3 = Student(
            id: "student2",
            teacherId: "teacher123",
            nis: "12345",
            name: "Ahmad"
        )

        #expect(student1 == student2) // Same ID
        #expect(student1 != student3) // Different ID
    }
}
