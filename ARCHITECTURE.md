# MargaSatya - Architecture Documentation

Deep dive into the architecture, design patterns, dan technical decisions untuk MargaSatya platform.

---

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Design Patterns](#design-patterns)
3. [Layer Architecture](#layer-architecture)
4. [Data Flow](#data-flow)
5. [Security Architecture](#security-architecture)
6. [State Management](#state-management)
7. [Network Layer](#network-layer)
8. [Dependency Injection](#dependency-injection)
9. [Testing Strategy](#testing-strategy)
10. [Performance Optimizations](#performance-optimizations)
11. [Trade-offs & Decisions](#trade-offs--decisions)

---

## 🏗️ Architecture Overview

### Architectural Style

**MVVM (Model-View-ViewModel) + Clean Architecture**

```
┌─────────────────────────────────────────────────────┐
│                    SwiftUI Views                     │  Presentation Layer
│                 (UI Components)                      │
└──────────────────┬──────────────────────────────────┘
                   │ Bindings (@Published)
┌──────────────────▼──────────────────────────────────┐
│                   ViewModels                         │  Presentation Logic
│              (@MainActor classes)                    │
└──────────────────┬──────────────────────────────────┘
                   │ Protocol Contracts
┌──────────────────▼──────────────────────────────────┐
│              Service Protocols                       │  Business Logic Interface
│    (Auth, Student, Exam, Session, Answer, Admin)    │
└──────────────────┬──────────────────────────────────┘
                   │ Implementation
┌──────────────────▼──────────────────────────────────┐
│           Firebase Services                          │  Data Layer
│         (Firestore, Auth APIs)                       │
└──────────────────┬──────────────────────────────────┘
                   │ Network
┌──────────────────▼──────────────────────────────────┐
│               Firebase Cloud                         │  Backend
│         (Firestore + Authentication)                 │
└─────────────────────────────────────────────────────┘
```

### Core Principles

1. **Separation of Concerns** - Each layer has single responsibility
2. **Protocol-Oriented** - All services defined as protocols
3. **Dependency Inversion** - Depend on abstractions, not concretions
4. **Testability** - Mock implementations untuk all services
5. **Reactive** - @Published properties untuk UI updates
6. **Async/Await** - Modern Swift concurrency throughout

### Key Characteristics

- **Unidirectional Data Flow** - State flows down, events flow up
- **Immutability** - Models are value types (structs)
- **Type Safety** - Strong typing with generics
- **Error Handling** - Explicit error types dengan Result/throws
- **Scalability** - Easy to add new features without affecting existing code

---

## 🎨 Design Patterns

### 1. MVVM (Model-View-ViewModel)

**Implementation:**

```swift
// MODEL - Data structure
struct Student: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String
    let nis: String
    let teacherId: String
}

// VIEWMODEL - Business logic + state
@MainActor
final class StudentListViewModel: ObservableObject {
    @Published var students: [Student] = []
    @Published var isLoading = false

    private let studentService: StudentServiceProtocol

    func loadStudents(teacherId: String) async {
        isLoading = true
        do {
            students = try await studentService.getStudents(forTeacher: teacherId)
        } catch {
            // Handle error
        }
        isLoading = false
    }
}

// VIEW - UI representation
struct StudentListView: View {
    @StateObject private var viewModel: StudentListViewModel

    var body: some View {
        List(viewModel.students) { student in
            Text(student.name)
        }
        .task {
            await viewModel.loadStudents(teacherId: teacherId)
        }
    }
}
```

**Benefits:**
- Clear separation between UI dan logic
- Testable business logic (test ViewModel without View)
- Reactive UI updates dengan @Published

### 2. Protocol-Oriented Programming

**Why Protocols?**

1. **Testability** - Easy to create mock implementations
2. **Flexibility** - Swap implementations (Firebase → CoreData)
3. **Dependency Inversion** - Depend on abstractions

**Example:**

```swift
// PROTOCOL - Contract
protocol StudentServiceProtocol {
    func getStudents(forTeacher teacherId: String) async throws -> [Student]
    func createStudent(_ student: Student) async throws -> String
    func updateStudent(_ student: Student) async throws
    func deleteStudent(studentId: String) async throws
}

// PRODUCTION IMPLEMENTATION
final class FirestoreStudentService: StudentServiceProtocol {
    private let db = Firestore.firestore()

    func getStudents(forTeacher teacherId: String) async throws -> [Student] {
        let snapshot = try await db.collection("students")
            .whereField("teacherId", isEqualTo: teacherId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments()

        return try snapshot.documents.compactMap { doc in
            try doc.data(as: Student.self)
        }
    }

    // ... other methods
}

// MOCK IMPLEMENTATION (for testing)
final class MockStudentService: StudentServiceProtocol {
    var studentsToReturn: [Student] = []
    var errorToThrow: Error?

    func getStudents(forTeacher teacherId: String) async throws -> [Student] {
        if let error = errorToThrow {
            throw error
        }
        return studentsToReturn
    }

    // ... other methods
}
```

**Usage in Tests:**

```swift
func testLoadStudents() async {
    // Arrange
    let mockService = MockStudentService()
    mockService.studentsToReturn = [
        Student(id: "1", name: "John", nis: "001", teacherId: "teacher1")
    ]
    let viewModel = StudentListViewModel(studentService: mockService)

    // Act
    await viewModel.loadStudents(teacherId: "teacher1")

    // Assert
    XCTAssertEqual(viewModel.students.count, 1)
    XCTAssertEqual(viewModel.students.first?.name, "John")
}
```

### 3. Dependency Injection (DI)

**DIContainer Pattern:**

```swift
final class DIContainer {
    static let shared = DIContainer()

    // MARK: - Core Services

    lazy var encryptionService: EncryptionServiceProtocol = {
        EncryptionService()
    }()

    lazy var networkMonitor: NetworkMonitorProtocol = {
        NetworkMonitor()
    }()

    lazy var authService: AuthServiceProtocol = {
        FirebaseAuthService()
    }()

    lazy var studentService: StudentServiceProtocol = {
        FirestoreStudentService()
    }()

    // ... other services

    // MARK: - ViewModel Factories

    func makeStudentListViewModel() -> StudentListViewModel {
        StudentListViewModel(studentService: studentService)
    }

    func makeStudentFormViewModel(student: Student? = nil) -> StudentFormViewModel {
        StudentFormViewModel(
            studentService: studentService,
            existingStudent: student
        )
    }

    // ... other factories
}
```

**Benefits:**
- Central location untuk dependency management
- Easy to swap implementations (testing vs production)
- Lazy initialization (services created when needed)
- Single source of truth

### 4. Repository Pattern

**Abstraction over Data Sources:**

```swift
// Service protocols act as repositories
protocol ExamServiceProtocol {
    // Repository methods
    func getExam(byId id: String) async throws -> Exam?
    func getExam(byAccessCode code: String) async throws -> Exam?
    func getExams(forTeacher teacherId: String) async throws -> [Exam]
    func createExam(_ exam: Exam) async throws -> String
    func updateExam(_ exam: Exam) async throws
    func deleteExam(examId: String) async throws

    // Subcollection operations
    func getQuestions(examId: String) async throws -> [ExamQuestion]
    func addQuestion(_ question: ExamQuestion, toExam examId: String) async throws -> String
    // ...
}
```

ViewModels never directly access Firestore - always through service protocols.

### 5. Strategy Pattern

**Example: Exam Type Handling**

```swift
enum ExamType: String, Codable {
    case googleForm = "GOOGLE_FORM"
    case inApp = "IN_APP"
}

// Different execution strategies based on type
struct Exam {
    let type: ExamType

    var executionStrategy: ExamExecutionStrategy {
        switch type {
        case .googleForm:
            return GoogleFormExecutionStrategy()
        case .inApp:
            return InAppExecutionStrategy()
        }
    }
}

protocol ExamExecutionStrategy {
    func startExam(session: ExamSession) async throws
    func submitExam(session: ExamSession) async throws
}
```

### 6. Observer Pattern

**SwiftUI + Combine:**

```swift
@MainActor
class StudentEntryViewModel: ObservableObject {
    @Published var nis = ""
    @Published var accessCode = ""

    // Observer pattern via Combine
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Observe changes to NIS field
        $nis
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.validateNIS(newValue)
            }
            .store(in: &cancellables)
    }
}
```

### 7. Factory Pattern

**ViewModel Factories in DIContainer:**

```swift
func makeExamFormViewModel(exam: Exam? = nil) -> ExamFormViewModel {
    ExamFormViewModel(
        examService: examService,
        studentService: studentService,
        existingExam: exam
    )
}
```

Creates ViewModels dengan proper dependencies injected.

---

## 🏛️ Layer Architecture

### Presentation Layer

**Components:**
- SwiftUI Views
- ViewModels
- UI Components (GlassButton, GlassCard, etc.)

**Responsibilities:**
- Render UI
- Handle user interactions
- Display data from ViewModels
- Navigation

**Files:**
```
Sources/Modules/
├── Auth/Views/
├── Teacher/Views/
├── Student/Views/
└── Admin/Views/
```

**Key Principles:**
- Views are dumb (no business logic)
- All state lives in ViewModels
- Views observe ViewModel via @Published
- Use @StateObject for ViewModel ownership

### Business Logic Layer

**Components:**
- ViewModels
- Validation logic
- State management
- Coordination

**Responsibilities:**
- Handle business rules
- Validate user input
- Coordinate service calls
- Manage presentation state

**Files:**
```
Sources/Modules/
├── Auth/ViewModels/
├── Teacher/ViewModels/
├── Student/ViewModels/
└── Admin/ViewModels/
```

**Example ViewModel:**

```swift
@MainActor
final class ExamFormViewModel: ObservableObject {
    // MARK: - Published Properties (observed by View)
    @Published var title = ""
    @Published var description = ""
    @Published var examType: ExamType = .inApp
    @Published var accessCode = ""
    @Published var formUrl = ""
    @Published var startTime: Date?
    @Published var endTime: Date?

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSaved = false

    // MARK: - Private Dependencies
    private let examService: ExamServiceProtocol
    private let teacherId: String
    private let existingExam: Exam?

    // MARK: - Computed Properties (business logic)
    var isFormValid: Bool {
        let basicValid = !title.isEmpty && !accessCode.isEmpty
        switch examType {
        case .googleForm:
            return basicValid && isUrlValid(formUrl)
        case .inApp:
            return basicValid
        }
    }

    // MARK: - Business Methods
    func saveExam() async {
        guard isFormValid else {
            errorMessage = "Please fill all required fields"
            return
        }

        isLoading = true

        do {
            let exam = buildExam()
            if let existing = existingExam {
                try await examService.updateExam(exam)
            } else {
                _ = try await examService.createExam(exam)
            }
            isSaved = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func buildExam() -> Exam {
        Exam(
            id: existingExam?.id,
            title: title,
            description: description,
            type: examType,
            formUrl: examType == .googleForm ? formUrl : nil,
            accessCode: accessCode,
            teacherId: teacherId,
            startTime: startTime,
            endTime: endTime
        )
    }
}
```

### Service Layer (Data Access)

**Components:**
- Service Protocols
- Firebase implementations
- Mock implementations

**Responsibilities:**
- Abstract data sources
- Execute network calls
- Handle Firebase operations
- Error handling

**Files:**
```
Sources/Data/Services/
├── Protocols/
│   ├── AuthServiceProtocol.swift
│   ├── StudentServiceProtocol.swift
│   ├── ExamServiceProtocol.swift
│   ├── ExamSessionServiceProtocol.swift
│   ├── ExamAnswerServiceProtocol.swift
│   └── AdminServiceProtocol.swift
└── Firebase/
    ├── FirebaseAuthService.swift
    ├── FirestoreStudentService.swift
    ├── FirestoreExamService.swift
    ├── FirestoreSessionService.swift
    ├── FirestoreAnswerService.swift
    └── FirestoreAdminService.swift
```

**Example Service:**

```swift
final class FirestoreExamService: ExamServiceProtocol {
    private let db = Firestore.firestore()
    private let examsCollection = "exams"

    func createExam(_ exam: Exam) async throws -> String {
        let docRef = try db.collection(examsCollection).addDocument(from: exam)
        return docRef.documentID
    }

    func getExam(byAccessCode code: String) async throws -> Exam? {
        let snapshot = try await db.collection(examsCollection)
            .whereField("accessCode", isEqualTo: code)
            .whereField("isActive", isEqualTo: true)
            .limit(to: 1)
            .getDocuments()

        return try snapshot.documents.first?.data(as: Exam.self)
    }

    // Subcollection operations
    func getQuestions(examId: String) async throws -> [ExamQuestion] {
        let snapshot = try await db.collection(examsCollection)
            .document(examId)
            .collection("questions")
            .order(by: "order", descending: false)
            .getDocuments()

        return try snapshot.documents.compactMap { doc in
            try doc.data(as: ExamQuestion.self)
        }
    }
}
```

### Model Layer

**Components:**
- Data models (structs)
- Enums
- Value types

**Responsibilities:**
- Define data structures
- Business rules dalam computed properties
- Codable conformance
- Validation logic

**Files:**
```
Sources/Data/Models/
├── User.swift
├── Student.swift
├── Exam.swift
├── ExamQuestion.swift
├── ExamParticipant.swift
├── ExamSession.swift
├── ExamAnswer.swift
└── AppConfig.swift
```

**Example Model:**

```swift
struct Exam: Codable, Identifiable {
    @DocumentID var id: String?
    let title: String
    let description: String
    let type: ExamType
    var formUrl: String?
    let accessCode: String
    let teacherId: String
    var startTime: Date?
    var endTime: Date?
    let createdAt: Date
    var isActive: Bool

    // MARK: - Computed Properties (business logic)

    var status: ExamStatus {
        let now = Date()

        if let end = endTime, now > end {
            return .ended
        }

        if let start = startTime {
            if now < start {
                return .upcoming
            } else if let end = endTime, now <= end {
                return .active
            }
        }

        return .active // No time restrictions
    }

    var isAccessible: Bool {
        isActive && (status == .active || status == .upcoming)
    }

    // MARK: - Validation

    func canAccess(at date: Date = Date()) -> (allowed: Bool, reason: String?) {
        guard isActive else {
            return (false, "Ujian tidak aktif")
        }

        if let start = startTime, date < start {
            return (false, "Ujian belum dimulai")
        }

        if let end = endTime, date > end {
            return (false, "Ujian sudah berakhir")
        }

        return (true, nil)
    }
}
```

---

## 🔄 Data Flow

### Read Operation (Display Data)

```
User Action (View)
    ↓
View calls ViewModel method
    ↓
ViewModel calls Service protocol method
    ↓
Service makes Firestore query
    ↓
Firestore returns data
    ↓
Service maps to Model
    ↓
ViewModel updates @Published property
    ↓
SwiftUI detects change, re-renders View
```

**Example:**

```swift
// 1. User taps "Load Students" button
Button("Load Students") {
    Task {
        await viewModel.loadStudents()
    }
}

// 2. ViewModel method called
@MainActor
func loadStudents() async {
    isLoading = true

    do {
        // 3. Service protocol called
        students = try await studentService.getStudents(forTeacher: teacherId)
        // 7. @Published property updated → SwiftUI re-renders
    } catch {
        errorMessage = error.localizedDescription
    }

    isLoading = false
}

// 4-6. Service implementation
func getStudents(forTeacher teacherId: String) async throws -> [Student] {
    let snapshot = try await db.collection("students")
        .whereField("teacherId", isEqualTo: teacherId)
        .getDocuments()

    return try snapshot.documents.compactMap { try $0.data(as: Student.self) }
}
```

### Write Operation (Save Data)

```
User Input (View)
    ↓
View binds to ViewModel @Published properties
    ↓
User taps "Save" button
    ↓
View calls ViewModel save method
    ↓
ViewModel validates input
    ↓
ViewModel builds Model from input
    ↓
ViewModel calls Service create/update method
    ↓
Service saves to Firestore
    ↓
Firestore returns document ID
    ↓
Service returns success
    ↓
ViewModel updates state (isSaved = true)
    ↓
View navigates away or shows success
```

### Encryption Flow (Special Case)

**Save Encrypted Answer:**

```
Student answers question
    ↓
View binds answer to ViewModel
    ↓
ViewModel auto-saves (every 2s)
    ↓
ViewModel calls EncryptionService.encrypt()
    ↓
EncryptionService:
  - Gets key from Keychain
  - Generates random IV
  - Encrypts with AES-256-GCM
  - Returns EncryptedAnswer
    ↓
ViewModel calls AnswerService.saveAnswer()
    ↓
AnswerService saves encrypted data to Firestore
    ↓
Success
```

**Retrieve Decrypted Answer (Teacher View):**

```
Teacher views session answers
    ↓
ViewModel calls AnswerService.getAnswers()
    ↓
AnswerService fetches from Firestore
    ↓
ViewModel calls EncryptionService.decrypt() for each
    ↓
EncryptionService:
  - Gets key from Keychain
  - Verifies authentication tag
  - Decrypts with AES-256-GCM
  - Returns plaintext
    ↓
ViewModel displays decrypted answers
```

---

## 🔐 Security Architecture

### Encryption Layer

**AES-256-GCM Implementation:**

```swift
final class EncryptionService: EncryptionServiceProtocol {
    private let keychainService = "com.secureexamid.encryption"
    private let keychainAccount = "exam-encryption-key"

    // Generate or retrieve encryption key
    func ensureEncryptionKeyExists() throws {
        if getEncryptionKey() == nil {
            let newKey = SymmetricKey(size: .bits256)
            try saveEncryptionKey(newKey)
        }
    }

    // Encrypt answer
    func encryptAnswer(plainText: String, forQuestionId questionId: String, sessionId: String) throws -> EncryptedAnswer {
        guard let key = getEncryptionKey() else {
            throw EncryptionError.keyNotFound
        }

        let plainData = Data(plainText.utf8)

        // Additional Authenticated Data (AAD)
        let aad = "\(questionId):\(sessionId)".data(using: .utf8)!

        // Encrypt with AES-256-GCM
        let sealedBox = try AES.GCM.seal(plainData, using: key, authenticating: aad)

        guard let cipherText = sealedBox.ciphertext,
              let tag = sealedBox.tag else {
            throw EncryptionError.encryptionFailed
        }

        let metadata = EncryptionMetadata(
            algorithm: "AES-256-GCM",
            iv: sealedBox.nonce.withUnsafeBytes { Data($0) },
            tag: tag,
            timestamp: Date()
        )

        return EncryptedAnswer(
            questionId: questionId,
            cipherText: cipherText,
            metadata: metadata
        )
    }

    // Decrypt answer
    func decryptAnswer(_ encrypted: EncryptedAnswer) throws -> String {
        guard let key = getEncryptionKey() else {
            throw EncryptionError.keyNotFound
        }

        // Reconstruct nonce
        let nonce = try AES.GCM.Nonce(data: encrypted.metadata.iv)

        // Reconstruct sealed box
        let sealedBox = try AES.GCM.SealedBox(
            nonce: nonce,
            ciphertext: encrypted.cipherText,
            tag: encrypted.metadata.tag
        )

        // AAD for verification
        let aad = "\(encrypted.questionId):\(encrypted.sessionId)".data(using: .utf8)!

        // Decrypt and verify tag
        let decryptedData = try AES.GCM.open(sealedBox, using: key, authenticating: aad)

        return String(data: decryptedData, encoding: .utf8) ?? ""
    }

    // iOS Keychain storage
    private func saveEncryptionKey(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw EncryptionError.keychainError(status)
        }
    }
}
```

**Security Properties:**

1. **AES-256-GCM:**
   - 256-bit key (max security)
   - Galois/Counter Mode (authenticated encryption)
   - Prevents tampering (authentication tag)

2. **IV (Initialization Vector):**
   - Random 96-bit nonce per encryption
   - Never reused
   - Stored with ciphertext

3. **AAD (Additional Authenticated Data):**
   - QuestionID + SessionID
   - Prevents ciphertext from being moved to different question/session

4. **Keychain Storage:**
   - Encryption key stored in iOS Keychain
   - `.whenUnlockedThisDeviceOnly` - max security
   - Hardware encryption on modern devices

### Firebase Security

**Firestore Rules:**

```javascript
// Teachers can only access their own students
match /students/{studentId} {
  allow read: if isTeacher() || isAdmin();
  allow write: if isTeacher() &&
                  request.resource.data.teacherId == request.auth.uid;
}

// Students (unauthenticated) can write sessions/answers
match /examSessions/{sessionId} {
  allow create: if true; // Student creates session without auth
  allow update: if true; // Student updates session (auto-save)
  allow read: if isTeacher() || isAdmin();
}
```

**Authentication:**

- Teachers/Admins: Firebase Auth (email/password)
- Students: No authentication (NIS + access code validation)

### Network Security

**App Transport Security (ATS):**

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
```

Forces HTTPS for all connections.

---

## 🎛️ State Management

### ViewModel State

**@Published Properties:**

```swift
@MainActor
final class StudentExamViewModel: ObservableObject {
    // Data state
    @Published var exam: Exam?
    @Published var questions: [ExamQuestion] = []
    @Published var currentQuestionIndex: Int = 0
    @Published var answers: [String: String] = [:] // questionId: answer

    // UI state
    @Published var isLoading = false
    @Published var showSubmitConfirmation = false
    @Published var timeRemaining: TimeInterval = 0

    // Error state
    @Published var errorMessage: String?
    @Published var showError = false

    // Navigation state
    @Published var isSubmitted = false
    @Published var navigationPath = NavigationPath()
}
```

**State Categories:**

1. **Data State** - Actual data (exams, students, etc.)
2. **UI State** - Loading indicators, alerts, modals
3. **Error State** - Error messages, error flags
4. **Navigation State** - Navigation paths, presented sheets

### View State

**@State for Local UI:**

```swift
struct ExamListView: View {
    @StateObject private var viewModel: ExamListViewModel

    // Local UI state (doesn't need to persist)
    @State private var showingFilters = false
    @State private var selectedExam: Exam?
    @State private var searchText = ""

    var body: some View {
        // ...
    }
}
```

**@StateObject vs @ObservedObject:**

- **@StateObject**: View owns ViewModel (lifecycle tied to view)
- **@ObservedObject**: View observes ViewModel owned elsewhere

### Persistence State

**UserDefaults for Simple Prefs:**

```swift
@AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false
@AppStorage("preferredExamType") var preferredExamType = "IN_APP"
```

**Firestore for App State:**

All important state (sessions, answers, etc.) saved to Firestore.

### Transient State

**In-Memory Only:**

```swift
// Timer state
private var countdownTimer: Timer?
private var autoSaveTimer: Timer?

// Combine subscriptions
private var cancellables = Set<AnyCancellable>()
```

Not persisted, recreated on app launch.

---

## 🌐 Network Layer

### Network Monitoring

```swift
@MainActor
final class NetworkMonitor: NetworkMonitorProtocol, ObservableObject {
    @Published private(set) var status: NetworkStatus = .unknown
    @Published private(set) var connectionType: ConnectionType = .unknown

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateStatus(path: path)
            }
        }
        monitor.start(queue: queue)
    }

    private func updateStatus(path: NWPath) {
        if path.status == .satisfied {
            status = .connected

            if path.usesInterfaceType(.wifi) {
                connectionType = .wifi
            } else if path.usesInterfaceType(.cellular) {
                connectionType = .cellular
            }
        } else {
            status = .disconnected
            connectionType = .unknown
        }
    }
}
```

### Retry Strategy

**Exponential Backoff:**

```swift
func retryOperation<T>(
    maxRetries: Int = 3,
    operation: () async throws -> T
) async throws -> T {
    var lastError: Error?

    for attempt in 0..<maxRetries {
        do {
            return try await operation()
        } catch {
            lastError = error

            if attempt < maxRetries - 1 {
                let delay = pow(2.0, Double(attempt)) // 1s, 2s, 4s
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    throw lastError ?? NetworkError.maxRetriesExceeded
}
```

### Firebase Offline Persistence

```swift
// Enable offline persistence
let settings = Firestore.firestore().settings
settings.isPersistenceEnabled = true
Firestore.firestore().settings = settings
```

Firestore automatically caches data and retries when online.

---

## 💉 Dependency Injection

### DIContainer Implementation

**Singleton Pattern:**

```swift
final class DIContainer {
    static let shared = DIContainer()

    private init() {
        // Private initializer (singleton)
    }

    // Lazy initialization
    lazy var encryptionService: EncryptionServiceProtocol = {
        EncryptionService()
    }()

    lazy var studentService: StudentServiceProtocol = {
        #if DEBUG
        if ProcessInfo.processInfo.environment["USE_MOCK"] == "1" {
            return MockStudentService()
        }
        #endif
        return FirestoreStudentService()
    }()
}
```

**ViewModel Factories:**

```swift
// Instead of:
StudentListViewModel(studentService: DIContainer.shared.studentService)

// Use factory:
DIContainer.shared.makeStudentListViewModel()
```

**Benefits:**

1. Centralized dependency management
2. Easy to swap implementations (mock vs real)
3. Lazy initialization (created when needed)
4. Testability (inject mocks easily)

### Testing with DI

```swift
class StudentListViewModelTests: XCTestCase {
    var mockStudentService: MockStudentService!
    var viewModel: StudentListViewModel!

    override func setUp() {
        super.setUp()
        mockStudentService = MockStudentService()
        viewModel = StudentListViewModel(studentService: mockStudentService)
    }

    func testLoadStudents_Success() async {
        // Arrange
        let expectedStudents = [
            Student(id: "1", name: "John", nis: "001", teacherId: "t1")
        ]
        mockStudentService.studentsToReturn = expectedStudents

        // Act
        await viewModel.loadStudents(teacherId: "t1")

        // Assert
        XCTAssertEqual(viewModel.students.count, 1)
        XCTAssertEqual(viewModel.students.first?.name, "John")
        XCTAssertFalse(viewModel.isLoading)
    }
}
```

---

## 🧪 Testing Strategy

### Test Pyramid

```
         /\
        /  \      E2E Tests (Manual)
       /────\     - Full app flows
      /      \    - TestFlight beta testing
     /   UI   \
    /  Tests   \  UI Tests (Future)
   /────────────\ - SwiftUI snapshot tests
  /              \
 / Integration    \ Integration Tests (Future)
/      Tests       \ - ViewModel + Real Firebase
/──────────────────\
|   Unit Tests     | Unit Tests (106 tests)
|   ============   | - Models (72 tests)
|                  | - Services (34 tests)
└──────────────────┘
```

### Unit Testing (TDD Approach)

**Model Tests:**

```swift
class ExamModelTests: XCTestCase {
    func testExamStatus_Upcoming() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let exam = Exam(
            title: "Test",
            type: .inApp,
            accessCode: "CODE",
            teacherId: "t1",
            startTime: tomorrow
        )

        XCTAssertEqual(exam.status, .upcoming)
    }

    func testCanAccess_BeforeStartTime() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let exam = Exam(
            title: "Test",
            type: .inApp,
            accessCode: "CODE",
            teacherId: "t1",
            startTime: tomorrow
        )

        let (allowed, reason) = exam.canAccess()

        XCTAssertFalse(allowed)
        XCTAssertEqual(reason, "Ujian belum dimulai")
    }
}
```

**Service Tests:**

```swift
class EncryptionServiceTests: XCTestCase {
    var encryptionService: EncryptionService!

    override func setUp() {
        super.setUp()
        encryptionService = EncryptionService()
        try? encryptionService.ensureEncryptionKeyExists()
    }

    func testEncryptDecrypt_Success() throws {
        let plainText = "My answer to question 1"
        let questionId = "q1"
        let sessionId = "s1"

        // Encrypt
        let encrypted = try encryptionService.encryptAnswer(
            plainText: plainText,
            forQuestionId: questionId,
            sessionId: sessionId
        )

        // Verify ciphertext is different
        XCTAssertNotEqual(
            String(data: encrypted.cipherText, encoding: .utf8),
            plainText
        )

        // Decrypt
        let decrypted = try encryptionService.decryptAnswer(encrypted)

        // Verify matches original
        XCTAssertEqual(decrypted, plainText)
    }

    func testDecrypt_TamperedData_ThrowsError() throws {
        let plainText = "Original answer"
        var encrypted = try encryptionService.encryptAnswer(
            plainText: plainText,
            forQuestionId: "q1",
            sessionId: "s1"
        )

        // Tamper with ciphertext
        encrypted.cipherText = Data("tampered".utf8)

        // Should throw error due to tag verification failure
        XCTAssertThrowsError(try encryptionService.decryptAnswer(encrypted))
    }
}
```

### Mock Services

```swift
final class MockExamService: ExamServiceProtocol {
    var examsToReturn: [Exam] = []
    var examToReturn: Exam?
    var errorToThrow: Error?
    var createCalled = false
    var updateCalled = false

    func getExams(forTeacher teacherId: String) async throws -> [Exam] {
        if let error = errorToThrow {
            throw error
        }
        return examsToReturn
    }

    func createExam(_ exam: Exam) async throws -> String {
        createCalled = true
        if let error = errorToThrow {
            throw error
        }
        return "mock-id-123"
    }
}
```

---

## ⚡ Performance Optimizations

### Lazy Loading

**ViewModels:**

```swift
lazy var examService: ExamServiceProtocol = {
    FirestoreExamService()
}()
```

Services created only when first accessed.

**Views:**

```swift
LazyVStack {
    ForEach(viewModel.students) { student in
        StudentRow(student: student)
    }
}
```

Renders only visible rows.

### Pagination (Future Enhancement)

```swift
func loadMoreStudents() async {
    let lastDoc = students.last?.firestoreDoc

    let query = db.collection("students")
        .whereField("teacherId", isEqualTo: teacherId)
        .order(by: "createdAt", descending: true)
        .start(afterDocument: lastDoc)
        .limit(to: 20)

    // Fetch next page
}
```

### Caching

**Firestore Offline Persistence:**

```swift
settings.isPersistenceEnabled = true
```

Automatically caches queries.

**Image Caching (Future):**

Use AsyncImage with caching for profile pictures.

### Debouncing Search

```swift
$searchText
    .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
    .sink { [weak self] text in
        self?.performSearch(text)
    }
    .store(in: &cancellables)
```

Reduces Firestore queries during typing.

### Minimize Firestore Reads

**Batch Reads:**

```swift
// Instead of multiple getDocument calls:
for id in questionIds {
    let doc = try await db.collection("questions").document(id).getDocument()
}

// Use single query:
let snapshot = try await db.collection("questions")
    .whereField(FieldPath.documentID(), in: questionIds)
    .getDocuments()
```

**Select Specific Fields (Future):**

```swift
.select(["name", "nis"]) // Only fetch needed fields
```

---

## ⚖️ Trade-offs & Decisions

### 1. Firebase vs Custom Backend

**Decision:** Firebase Firestore + Authentication

**Pros:**
- ✅ Fast development (no backend code)
- ✅ Real-time sync out of box
- ✅ Offline persistence built-in
- ✅ Security rules declarative
- ✅ Auto-scaling
- ✅ Free tier sufficient for MVP

**Cons:**
- ❌ Vendor lock-in
- ❌ Complex queries limited
- ❌ Cost can scale with usage
- ❌ No server-side logic (Cloud Functions required)

**Mitigation:**
- Protocol-oriented design makes swapping backend easier
- Can migrate to custom backend if needed

### 2. Students Without Authentication

**Decision:** Students access with NIS + Access Code (no Firebase Auth)

**Pros:**
- ✅ Simpler UX (no signup/login)
- ✅ Faster exam access
- ✅ No email required
- ✅ Privacy-friendly

**Cons:**
- ❌ Can't use Firebase Auth for authorization
- ❌ Firestore rules must allow unauthenticated writes
- ❌ Potential for abuse (spam sessions)

**Mitigation:**
- Server-side validation (NIS + accessCode)
- Rate limiting via Firebase App Check (future)
- Firestore rules prevent reading others' data

### 3. Client-Side Encryption vs Server-Side

**Decision:** Client-side AES-256-GCM encryption

**Pros:**
- ✅ Zero-knowledge architecture (even Firebase admins can't read answers)
- ✅ Maximum privacy
- ✅ Encryption key never leaves device
- ✅ No server-side code needed

**Cons:**
- ❌ If key lost, data unrecoverable
- ❌ Can't search encrypted data
- ❌ More complex key management
- ❌ Performance overhead

**Mitigation:**
- Keychain ensures key persistence
- Only exam answers encrypted (metadata searchable)
- Hardware-accelerated AES on modern devices

### 4. MVVM vs VIPER/Clean Architecture

**Decision:** MVVM with Protocol-Oriented Services

**Pros:**
- ✅ Simpler than VIPER (less boilerplate)
- ✅ SwiftUI-friendly
- ✅ Clear separation of concerns
- ✅ Testable

**Cons:**
- ❌ ViewModels can grow large
- ❌ Navigation logic in ViewModels (not ideal)

**Mitigation:**
- Break large ViewModels into smaller ones
- Use Coordinator pattern (future) for complex navigation

### 5. Auto-Save Every 2 Seconds

**Decision:** Debounced auto-save with 2-second delay

**Pros:**
- ✅ Prevents data loss
- ✅ User doesn't need to remember to save
- ✅ Resume functionality works

**Cons:**
- ❌ Firestore write costs (but minimal with debounce)
- ❌ Potential for partial answers if network fails

**Mitigation:**
- Debounce prevents excessive writes
- SUBMISSION_PENDING state handles offline
- Network retry with exponential backoff

### 6. Monolithic App vs Multi-Module

**Decision:** Single-target app with clear folder structure

**Pros:**
- ✅ Simpler build setup
- ✅ Faster compile (no module boundaries)
- ✅ Easier refactoring

**Cons:**
- ❌ Can't independently version modules
- ❌ Larger binary (but not significant for this app)

**Future:** Can modularize if app grows significantly.

---

## 📚 Architecture Evolution

### Current: Version 1.0

- MVVM + Protocol-Oriented
- Firebase Firestore backend
- Client-side encryption
- 3-role system

### Future Enhancements

**Phase 9: Advanced Features**
- **Coordinator Pattern** for navigation
- **Repository Layer** explicit abstraction
- **Use Cases** for complex business logic
- **Combine + Async/Await** deeper integration

**Phase 10: Enterprise**
- **Multi-Tenancy** support (multiple schools)
- **Modular Architecture** (feature modules)
- **Microservices** backend (if scale requires)
- **GraphQL** for flexible queries

---

## 📖 References & Resources

### Architecture Patterns

- [Swift.org - API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Apple - SwiftUI Architecture](https://developer.apple.com/documentation/swiftui)
- [MVVM in SwiftUI](https://www.swiftbysundell.com/articles/mvvm-in-swiftui/)
- [Protocol-Oriented Programming](https://developer.apple.com/videos/play/wwdc2015/408/)

### Security

- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [iOS Security Guide](https://support.apple.com/guide/security/welcome/web)
- [AES-GCM](https://en.wikipedia.org/wiki/Galois/Counter_Mode)

### Firebase

- [Firestore Data Modeling](https://firebase.google.com/docs/firestore/manage-data/structure-data)
- [Firebase Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Best Practices](https://firebase.google.com/docs/firestore/best-practices)

---

**Last Updated:** 2025-11-17
**Architecture Version:** 1.0
**Status:** ✅ Production Ready
