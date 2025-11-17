# SecureExamID - Platform Ujian Terenkripsi

**Version:** 2.0
**Platform:** iOS 15+ (iPhone XR+)
**Tech Stack:** Swift 5+, SwiftUI, Firebase Firestore, AES-256-GCM
**Status:** ✅ Production Ready

---

## 📱 Overview

SecureExamID adalah platform ujian komprehensif untuk iOS dengan sistem 3-role (Siswa, Guru, Admin) yang mendukung dua jenis ujian: **Google Form** dan **In-App**. Aplikasi ini dibangun dengan standar enterprise menggunakan enkripsi AES-256-GCM, Firebase Firestore backend, dan architecture MVVM yang testable.

### 🎯 Key Differentiators

- **3-Role System** - Siswa (tanpa auth), Guru (full CRUD), Admin (monitoring)
- **Dual Exam Types** - Google Form (WebView) + In-App (native dengan enkripsi)
- **Enterprise Security** - AES-256-GCM encryption untuk semua jawaban ujian
- **Production-Ready** - 106 unit tests, SOLID principles, clean architecture
- **Offline Support** - SUBMISSION_PENDING state dengan auto-retry
- **Auto-Save & Resume** - Jawaban ter-save otomatis setiap 2 detik
- **Real-Time Statistics** - Dashboard admin dengan system metrics
- **Liquid Glass UI** - Modern glassmorphic design, semua teks Bahasa Indonesia

---

## ✨ Features by Role

### 👨‍🎓 Siswa (Student)

**Authentication:** None - hanya NIS + Access Code

**Capabilities:**
- ✅ Masuk ujian dengan NIS + kode akses
- ✅ Mengerjakan ujian Google Form (WebView lockdown)
- ✅ Mengerjakan ujian In-App (multiple choice + essay)
- ✅ Auto-save jawaban setiap 2 detik
- ✅ Resume ujian yang terinterupsi
- ✅ Lihat timer countdown real-time
- ✅ Submit ujian (manual atau auto saat waktu habis)
- ✅ Offline handling dengan retry otomatis

**Exam Flow:**
1. Input NIS + Kode Akses → Validasi
2. View exam info → Start exam
3. Answer questions → Auto-save
4. Submit → Encryption → Firestore

### 👨‍🏫 Guru (Teacher)

**Authentication:** Email + Password (Firebase Auth)

**Student Management:**
- ✅ Create, read, update, delete siswa
- ✅ Search siswa by name/NIS
- ✅ Validasi NIS unique per teacher
- ✅ Bulk student operations

**Exam Management:**
- ✅ Create ujian (Google Form atau In-App)
- ✅ Edit, duplicate, delete ujian
- ✅ Filter by type (Google Form / In-App)
- ✅ Filter by status (Upcoming / Active / Ended)
- ✅ Set access code, start/end time
- ✅ Select participating students

**Question Management (In-App only):**
- ✅ Create multiple choice questions (2-6 options)
- ✅ Create essay questions
- ✅ Drag-to-reorder questions
- ✅ Set correct answers dan poin
- ✅ View question statistics

**Session Monitoring:**
- ✅ View active exam sessions
- ✅ Monitor student progress
- ✅ View submitted answers (decrypted)

### 👨‍💼 Admin

**Authentication:** Email + Password + Admin Key

**Capabilities:**
- ✅ View system summary statistics
  - Total guru, siswa, ujian
  - Ujian berjalan saat ini
  - Sesi hari ini
- ✅ View daftar guru terdaftar
- ✅ View statistik per-guru:
  - Total students managed
  - Total exams created
  - Total sessions conducted
  - Active exams count
- ✅ Future: System configuration, user management

---

## 🏗️ Architecture

### Design Patterns

**MVVM (Model-View-ViewModel)**
- Clear separation of concerns
- Testable business logic
- Reactive UI updates dengan @Published

**Protocol-Oriented Programming**
- 6 service protocols untuk testability
- Mock implementations untuk unit testing
- Dependency injection via DIContainer

**Clean Code Principles**
- SOLID principles
- Single Responsibility
- Dependency Inversion
- Interface Segregation

**Test-Driven Development (TDD)**
- 106 unit tests written FIRST
- Tests for all models and services
- Mock services untuk isolated testing

### Project Structure

```
MargaSatya/
├── Sources/
│   ├── Core/
│   │   ├── DI/
│   │   │   └── DIContainer.swift              # Dependency injection
│   │   ├── Encryption/
│   │   │   └── EncryptionService.swift        # AES-256-GCM encryption
│   │   ├── Network/
│   │   │   └── NetworkMonitor.swift           # Connectivity monitoring
│   │   ├── Configuration/
│   │   │   └── AppConfiguration.swift         # Centralized config
│   │   └── UI/
│   │       ├── GlassBackground.swift          # Liquid glass UI
│   │       ├── GlassButton.swift
│   │       ├── GlassTextField.swift
│   │       └── UIConstants.swift
│   │
│   ├── Data/
│   │   ├── Models/
│   │   │   ├── User.swift                     # User model (3 roles)
│   │   │   ├── Student.swift                  # Student model
│   │   │   ├── Exam.swift                     # Exam model (2 types)
│   │   │   ├── ExamQuestion.swift             # Question model (MC + essay)
│   │   │   ├── ExamParticipant.swift
│   │   │   ├── ExamSession.swift              # Session with 4 states
│   │   │   ├── ExamAnswer.swift
│   │   │   └── AppConfig.swift
│   │   │
│   │   └── Services/
│   │       ├── Protocols/                     # Service contracts
│   │       │   ├── AuthServiceProtocol.swift
│   │       │   ├── StudentServiceProtocol.swift
│   │       │   ├── ExamServiceProtocol.swift
│   │       │   ├── ExamSessionServiceProtocol.swift
│   │       │   ├── ExamAnswerServiceProtocol.swift
│   │       │   └── AdminServiceProtocol.swift
│   │       │
│   │       └── Firebase/                      # Firestore implementations
│   │           ├── FirebaseAuthService.swift
│   │           ├── FirestoreStudentService.swift
│   │           ├── FirestoreExamService.swift
│   │           ├── FirestoreSessionService.swift
│   │           ├── FirestoreAnswerService.swift
│   │           └── FirestoreAdminService.swift
│   │
│   └── Modules/
│       ├── Auth/
│       │   ├── ViewModels/
│       │   │   ├── TeacherAuthViewModel.swift
│       │   │   └── AdminAuthViewModel.swift
│       │   └── Views/
│       │       ├── RoleSelectionView.swift
│       │       ├── TeacherAuthView.swift
│       │       └── AdminAuthView.swift
│       │
│       ├── Teacher/
│       │   ├── ViewModels/
│       │   │   ├── StudentListViewModel.swift
│       │   │   ├── StudentFormViewModel.swift
│       │   │   ├── ExamListViewModel.swift
│       │   │   ├── ExamFormViewModel.swift
│       │   │   ├── QuestionListViewModel.swift
│       │   │   ├── QuestionFormViewModel.swift
│       │   │   └── ParticipantSelectionViewModel.swift
│       │   └── Views/
│       │       ├── TeacherHomeView.swift
│       │       ├── StudentListView.swift
│       │       ├── StudentFormView.swift
│       │       ├── ExamListView.swift
│       │       ├── ExamFormView.swift
│       │       ├── QuestionListView.swift
│       │       ├── QuestionFormView.swift
│       │       └── ParticipantSelectionView.swift
│       │
│       ├── Student/
│       │   ├── ViewModels/
│       │   │   ├── StudentEntryViewModel.swift
│       │   │   ├── StudentExamViewModel.swift
│       │   │   └── GoogleFormExamViewModel.swift
│       │   └── Views/
│       │       ├── StudentEntryView.swift
│       │       ├── StudentExamView.swift
│       │       ├── GoogleFormExamView.swift
│       │       └── SubmissionPendingView.swift
│       │
│       └── Admin/
│           ├── ViewModels/
│           │   ├── AdminDashboardViewModel.swift
│           │   └── TeacherStatsViewModel.swift
│           └── Views/
│               ├── AdminDashboardView.swift
│               └── TeacherStatsView.swift
│
├── Tests/
│   ├── ModelTests/                            # TDD tests
│   │   ├── UserModelTests.swift
│   │   ├── StudentModelTests.swift
│   │   ├── ExamModelTests.swift
│   │   ├── ExamQuestionModelTests.swift
│   │   └── ExamSessionModelTests.swift
│   └── ServiceTests/
│       ├── EncryptionServiceTests.swift
│       └── NetworkMonitorTests.swift
│
└── SecureExamIDApp.swift                      # App entry point

```

### Key Services

#### 1. EncryptionService (AES-256-GCM)
```swift
protocol EncryptionServiceProtocol {
    func encryptAnswer(plainText: String, forQuestionId: String, sessionId: String) throws -> EncryptedAnswer
    func decryptAnswer(_ encrypted: EncryptedAnswer) throws -> String
    func ensureEncryptionKeyExists() throws
    func removeEncryptionKey() throws
}
```

**Features:**
- AES-256-GCM authenticated encryption
- iOS Keychain untuk key storage
- IV (Initialization Vector) generation
- Tamper detection via authentication tag
- Metadata tracking (timestamp, algorithm)

#### 2. NetworkMonitor
```swift
protocol NetworkMonitorProtocol {
    var status: NetworkStatus { get }
    var connectionType: ConnectionType { get }
    var statusPublisher: AnyPublisher<NetworkStatus, Never> { get }

    func startMonitoring()
    func stopMonitoring()
    func retryOperation<T>(maxRetries: Int, operation: () async throws -> T) async throws -> T
}
```

**Features:**
- Real-time connectivity monitoring
- WiFi vs Cellular detection
- Exponential backoff retry strategy
- Combine publisher untuk reactive updates

#### 3. FirestoreExamService (Most Complex)
```swift
protocol ExamServiceProtocol {
    func createExam(_ exam: Exam) async throws -> String
    func updateExam(_ exam: Exam) async throws
    func deleteExam(examId: String) async throws
    func getExam(byId id: String) async throws -> Exam?
    func getExam(byAccessCode code: String) async throws -> Exam?
    func getExams(forTeacher teacherId: String) async throws -> [Exam]
    // + 9 more methods for questions, participants, etc.
}
```

**Features:**
- Main exam CRUD operations
- Subcollections handling (questions, participants)
- Access code validation
- Time-based status computation
- Soft delete dengan isActive flag

---

## 🔒 Security Features

### 1. Encryption (AES-256-GCM)

**What's Encrypted:**
- Semua jawaban ujian In-App (multiple choice + essay)
- Setiap jawaban encrypted individually dengan:
  - Unique IV per jawaban
  - Question ID + Session ID sebagai additional authenticated data (AAD)
  - Authentication tag untuk tamper detection

**Key Management:**
- Encryption key stored di iOS Keychain
- Key access control: `.whenUnlockedThisDeviceOnly`
- Key rotation support (future)

**Encryption Flow:**
```
Student Answer → Plain Text
    ↓
AES-256-GCM Encrypt (Key from Keychain, Random IV, AAD: questionId+sessionId)
    ↓
EncryptedAnswer { cipherText, IV, tag, metadata }
    ↓
Firestore Storage (Base64 encoded)
```

**Decryption Flow (Teacher View):**
```
Firestore → EncryptedAnswer
    ↓
AES-256-GCM Decrypt (Key from Keychain, Verify tag)
    ↓
Plain Text Answer
```

### 2. Firebase Security Rules

**Firestore Rules** (See `FIREBASE_SETUP.md`):
- Students: Read own sessions/answers only
- Teachers: CRUD own students/exams
- Admins: Read-only access untuk statistics
- Role-based access control via custom claims

**Authentication:**
- Firebase Auth dengan email/password
- Admin key validation untuk admin role
- No authentication untuk siswa (NIS-based access)

### 3. WebView Security (Google Form Exams)

- Private browsing mode (no cache)
- Domain whitelist (hanya Google domains)
- Disable context menu
- Disable new window/tab
- External link interception

### 4. Data Validation

- Server-side validation di Firestore rules
- Client-side validation di ViewModels
- NIS uniqueness per teacher
- Access code validation
- Time-based access control

---

## 🚀 Getting Started

### Prerequisites

1. **Xcode 15+**
2. **iOS 15+** deployment target
3. **Firebase Project** (Firestore + Authentication)
4. **Apple Developer Account** (untuk provisioning)
5. **CocoaPods atau SPM** untuk dependencies

### Installation

#### Step 1: Clone Repository

```bash
git clone https://github.com/yourusername/MargaSatya.git
cd MargaSatya
```

#### Step 2: Firebase Setup

Ikuti panduan lengkap di **[FIREBASE_SETUP.md](FIREBASE_SETUP.md)**

**Quick Setup:**

1. Buat Firebase project di [Firebase Console](https://console.firebase.google.com)
2. Enable **Firestore** dan **Authentication** (Email/Password)
3. Download `GoogleService-Info.plist` → Add ke Xcode project
4. Install Firebase SDK via Swift Package Manager:
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```
   Select: FirebaseFirestore, FirebaseAuth
5. Update Firestore Security Rules (lihat FIREBASE_SETUP.md)

#### Step 3: Xcode Configuration

1. Open `MargaSatya.xcodeproj` di Xcode
2. Select target **MargaSatya**
3. **Signing & Capabilities:**
   - Select your team
   - Set bundle identifier (e.g., `com.yourcompany.secureexamid`)
4. **Info.plist:**
   - Already configured untuk Firebase dan ATS
5. Build & Run (Cmd + R)

### First Run Setup

#### Create Admin Account (Via Firebase Console)

1. Buka Firebase Console → Authentication
2. Add user manually:
   - Email: `admin@example.com`
   - Password: `admin123`
3. Buka Firestore → Collection `users`
4. Add document dengan ID = Auth UID:
   ```json
   {
     "name": "Super Admin",
     "email": "admin@example.com",
     "role": "ADMIN",
     "authUID": "<Firebase Auth UID>",
     "createdAt": <Timestamp>
   }
   ```

#### Create Teacher Account (Via App)

1. Launch app → Select "Guru"
2. Tab "Daftar"
3. Register dengan email + password
4. Login → Start creating students/exams

---

## 📊 Firebase Structure

### Firestore Collections

#### `users` Collection
```
users/{userId}
  - name: string
  - email: string
  - role: "ADMIN" | "GURU" | "SISWA"
  - authUID: string (Firebase Auth UID)
  - createdAt: timestamp
  - isActive: boolean
```

#### `students` Collection
```
students/{studentId}
  - name: string
  - nis: string (unique per teacher)
  - teacherId: string (reference to users)
  - createdAt: timestamp
  - isActive: boolean
```

#### `exams` Collection
```
exams/{examId}
  - title: string
  - description: string
  - type: "GOOGLE_FORM" | "IN_APP"
  - formUrl: string? (only for GOOGLE_FORM)
  - accessCode: string (unique)
  - teacherId: string
  - startTime: timestamp?
  - endTime: timestamp?
  - createdAt: timestamp
  - isActive: boolean

  SUBCOLLECTIONS:

  /questions/{questionId}  (only for IN_APP)
    - questionText: string
    - type: "MULTIPLE_CHOICE" | "ESSAY"
    - options: [string]? (only for MC)
    - correctAnswer: string? (only for MC)
    - points: number
    - order: number

  /participants/{participantId}
    - studentId: string
    - nis: string
    - studentName: string
    - hasAccess: boolean
```

#### `examSessions` Collection
```
examSessions/{sessionId}
  - examId: string
  - studentId: string
  - nis: string
  - status: "NOT_STARTED" | "IN_PROGRESS" | "SUBMITTED" | "SUBMISSION_PENDING"
  - startedAt: timestamp?
  - submittedAt: timestamp?
  - currentQuestionIndex: number?
  - answeredQuestionIds: [string]?

  SUBCOLLECTION:

  /answers/{answerId}
    - questionId: string
    - answerText: string (ENCRYPTED for IN_APP)
    - answeredAt: timestamp
    - encryptionMetadata: object? (algorithm, IV, etc.)
```

#### `appConfig` Collection
```
appConfig/settings
  - maintenanceMode: boolean
  - minAppVersion: string
  - adminKey: string (hashed)
```

---

## 🧪 Testing

### Unit Tests (106 Tests)

**Run Tests:**
```bash
# Di Xcode
Cmd + U

# CLI
xcodebuild test -scheme MargaSatya -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Test Coverage:**
- ✅ User model (14 tests): Role permissions, validation
- ✅ Student model (12 tests): NIS validation, JSON encoding
- ✅ Exam model (15 tests): Status computation, access control, validation
- ✅ ExamQuestion model (18 tests): Type-specific validation, options
- ✅ ExamSession model (13 tests): State transitions, resume logic
- ✅ EncryptionService (19 tests): Encrypt/decrypt, key management, error handling
- ✅ NetworkMonitor (15 tests): Status detection, retry strategy

### Manual Testing Guide

#### Test Siswa Flow

1. **Setup** (sebagai Guru):
   - Create student: "Test Student", NIS: "12345"
   - Create IN_APP exam: "Test Ujian"
   - Add 5 multiple choice questions
   - Add student "12345" sebagai participant
   - Note access code

2. **Test** (sebagai Siswa):
   - Select "Siswa" role
   - Input NIS: `12345`
   - Input Access Code: `<your code>`
   - Start exam
   - Answer questions → Verify auto-save (watch console logs)
   - Close app → Reopen → Verify resume works
   - Submit → Verify success

3. **Verify** (sebagai Guru):
   - View sessions → Check submitted session
   - View answers → Verify decryption works

#### Test Google Form Exam

1. Create exam with type = GOOGLE_FORM
2. Set valid Google Form URL
3. Student flow → Should open WebView
4. Verify session tracking works

#### Test Offline Scenario

1. Start exam as student
2. Turn off WiFi during exam
3. Answer questions → Should save locally
4. Submit → Should show SUBMISSION_PENDING
5. Turn WiFi back on → Should auto-retry and succeed

---

## 📖 Development Guidelines

### Code Style

- **Swift:** Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- **Naming:** Descriptive names (no abbreviations except standard ones)
- **Comments:** Use `// MARK:` untuk organize code sections
- **Access Control:** Use `private` by default, expose hanya yang necessary
- **Async/Await:** Use async/await (not completion handlers)

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/exam-analytics

# Commit dengan descriptive message
git commit -m "feat: Add exam analytics dashboard"

# Push to remote
git push origin feature/exam-analytics

# Create PR untuk review
```

**Commit Message Format:**
- `feat:` New feature
- `fix:` Bug fix
- `refactor:` Code refactoring
- `test:` Add tests
- `docs:` Documentation update

### Adding New Features

1. **Write tests first** (TDD approach)
2. **Create protocol** untuk service layer
3. **Implement service** (production + mock)
4. **Create ViewModel** dengan @Published properties
5. **Create View** dengan SwiftUI
6. **Update DIContainer** untuk DI
7. **Test manually** di simulator dan device
8. **Commit** dengan descriptive message

---

## 🐛 Troubleshooting

### Firebase Connection Failed

**Error:** "Failed to fetch document"

**Solutions:**
1. Verify `GoogleService-Info.plist` is added to project
2. Check Firebase project is active
3. Verify internet connection
4. Check Firestore rules (lihat FIREBASE_SETUP.md)

### Encryption Failed

**Error:** "Encryption key not found"

**Solutions:**
1. Delete app and reinstall (clears Keychain)
2. Check entitlements untuk Keychain access
3. Verify iOS version 15+ (Keychain APIs)

### Tests Failing

**Error:** Multiple test failures

**Solutions:**
1. Clean build folder: `Cmd + Shift + K`
2. Reset simulator: `Device → Erase All Content and Settings`
3. Rebuild: `Cmd + B`
4. Run tests again: `Cmd + U`

### App Crashes on Launch

**Error:** "Firebase not configured"

**Solutions:**
1. Check `GoogleService-Info.plist` is in main bundle
2. Verify `FirebaseApp.configure()` is called in `SecureExamIDApp.swift`
3. Check Firebase SDK version compatibility

---

## 📚 Documentation

- **[PROGRESS.md](PROGRESS.md)** - Detailed implementation progress (8 phases)
- **[FIREBASE_SETUP.md](FIREBASE_SETUP.md)** - Firebase configuration guide
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Production deployment guide
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Architecture deep dive

---

## 📈 Roadmap

### Phase 9: Advanced Features (Future)

- [ ] **Proctoring:** Camera monitoring dengan face detection
- [ ] **Analytics:** Exam behavior tracking dan cheating detection
- [ ] **Push Notifications:** Exam reminders untuk students
- [ ] **Export:** Export results ke PDF/Excel
- [ ] **Grading:** Auto-grading untuk essay dengan AI
- [ ] **Localization:** English language support
- [ ] **iPad Support:** Optimized UI untuk iPad
- [ ] **macOS Catalyst:** Run on Mac

### Phase 10: Enterprise Features

- [ ] **MDM Integration:** Enterprise device management
- [ ] **SSO:** Single Sign-On dengan SAML/OAuth
- [ ] **Multi-Tenancy:** Support multiple organizations
- [ ] **Advanced Reporting:** Custom reports dan data export
- [ ] **API:** REST API untuk integration
- [ ] **Webhooks:** Event notifications
- [ ] **Audit Logs:** Comprehensive activity logging

---

## 📊 Project Statistics

### Code Metrics
- **Total Files:** 60+ Swift files
- **Lines of Code:** ~9,500+ lines
- **ViewModels:** 18 ViewModels
- **Views:** 25+ SwiftUI views
- **Services:** 6 service protocols + 6 Firestore implementations
- **Data Models:** 8 models
- **Unit Tests:** 106 tests (TDD approach)

### Development Time
- **Total Time:** ~39 hours
- **Phase 1 (Foundation):** ~3 hours
- **Phase 2 (Data & Services):** ~6 hours
- **Phase 3 (Auth):** ~3 hours
- **Phase 4 (Teacher-Students):** ~4 hours
- **Phase 5 (Teacher-Exams):** ~8 hours
- **Phase 6 (Student-Exam):** ~10 hours
- **Phase 7 (Admin):** ~3 hours
- **Phase 8 (Testing & Polish):** ~2 hours

---

## 👥 Contributors

Built with ❤️ by the SecureExamID team.

---

## 📄 License

Copyright © 2025 SecureExamID. All rights reserved.

This is proprietary educational software. Unauthorized copying, modification, or distribution is prohibited.

---

## 🙏 Acknowledgments

- **Firebase** - Backend infrastructure
- **Apple** - SwiftUI framework dan iOS platform
- **Swift Community** - Open source libraries dan best practices

---

## 📞 Support

Untuk pertanyaan, bug reports, atau feature requests:
- Open issue di GitHub repository
- Email: support@secureexamid.com
- Documentation: [docs.secureexamid.com](https://docs.secureexamid.com)

---

**SecureExamID** - Platform Ujian Terenkripsi untuk Institusi Pendidikan Modern
