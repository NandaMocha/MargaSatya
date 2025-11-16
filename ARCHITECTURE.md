# MargaSatya - Architecture Documentation

## 📐 Architecture Overview

MargaSatya menggunakan **MVVM (Model-View-ViewModel)** pattern dengan **SOLID principles** dan **Clean Code** practices untuk memastikan kode yang maintainable, testable, dan scalable.

---

## 🏗️ Complete Architecture Stack

```
┌─────────────────────────────────────────────────────────┐
│                         Views                           │
│  (SwiftUI - Presentation Layer)                         │
│  - ExamCodeInputView                                    │
│  - ExamPreparationView                                  │
│  - SecureExamView                                       │
│  - ExamCompletedView                                    │
└────────────────┬────────────────────────────────────────┘
                 │ Bindings
┌────────────────▼────────────────────────────────────────┐
│                     ViewModels                          │
│  (Business Logic Layer)                                 │
│  - ExamCodeInputViewModel                               │
│  - ExamPreparationViewModel                             │
│  - SecureExamViewModel                                  │
└────────────────┬────────────────────────────────────────┘
                 │ Protocols (Dependency Inversion)
┌────────────────▼────────────────────────────────────────┐
│                      Services                           │
│  (Business Services Layer)                              │
│  - ExamAPIService (Protocol: ExamAPIServiceProtocol)    │
│  - AssessmentModeManager (Protocol: AssessmentMode...)  │
│  - SecureWebViewCoordinator                             │
└────────────────┬────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────┐
│                       Models                            │
│  (Data Layer)                                           │
│  - ExamSession                                          │
│  - ExamResponse                                         │
│  - ExamCodeRequest                                      │
└─────────────────────────────────────────────────────────┘
```

---

## 🎯 SOLID Principles Implementation

### 1. **Single Responsibility Principle (SRP)**

Setiap class memiliki satu tanggung jawab:

```swift
// ✅ GOOD: Each class has single responsibility
class ExamCodeInputViewModel {
    // Only handles exam code input logic
}

class ExamAPIService {
    // Only handles API communication
}

class AssessmentModeManager {
    // Only handles AAC (Assessment Mode)
}
```

### 2. **Open/Closed Principle (OCP)**

Services terbuka untuk extension tapi tertutup untuk modification melalui protocols:

```swift
// Protocol allows extending functionality
protocol ExamAPIServiceProtocol {
    func resolveExamCode(_ code: String) async throws -> ExamResponse
}

// Production implementation
class ExamAPIService: ExamAPIServiceProtocol { }

// Mock implementation for testing
class MockExamAPIService: ExamAPIServiceProtocol { }
```

### 3. **Liskov Substitution Principle (LSP)**

Setiap implementasi protocol dapat disubstitusi tanpa mengubah behavior:

```swift
// Both can be used interchangeably
let apiService: ExamAPIServiceProtocol = ExamAPIService()
let mockService: ExamAPIServiceProtocol = MockExamAPIService()
```

### 4. **Interface Segregation Principle (ISP)**

Protocols kecil dan spesifik, tidak memaksa implementasi method yang tidak digunakan:

```swift
protocol ExamAPIServiceProtocol {
    func resolveExamCode(_ code: String) async throws -> ExamResponse
}

protocol AssessmentModeServiceProtocol: ObservableObject {
    var isInAssessmentMode: Bool { get }
    var isAssessmentModeAvailable: Bool { get }
    func startAssessmentMode() async throws
    func endAssessmentMode()
    func forceEndAssessment()
}
```

### 5. **Dependency Inversion Principle (DIP)**

High-level modules (ViewModels) bergantung pada abstractions (Protocols), bukan concrete implementations:

```swift
// ViewModel depends on protocol, not concrete class
class ExamCodeInputViewModel {
    private let apiService: ExamAPIServiceProtocol // ← Protocol!

    init(apiService: ExamAPIServiceProtocol) {
        self.apiService = apiService
    }
}
```

---

## 💉 Dependency Injection

### DIContainer

Centralized dependency management menggunakan DI Container:

```swift
final class DIContainer {
    static let shared = DIContainer()

    // Lazy initialization of services
    private(set) lazy var apiService: ExamAPIServiceProtocol = {
        if AppConfiguration.Features.isDevelopmentMode {
            return MockExamAPIService()
        } else {
            return ExamAPIService(baseURL: AppConfiguration.API.baseURL)
        }
    }()

    // Factory methods for ViewModels
    func makeExamCodeInputViewModel() -> ExamCodeInputViewModel {
        return ExamCodeInputViewModel(apiService: apiService)
    }
}
```

### Benefits:

- ✅ **Testable**: Mudah inject mock dependencies
- ✅ **Flexible**: Ganti implementation tanpa ubah code
- ✅ **Centralized**: Semua dependencies di satu tempat
- ✅ **Type-safe**: Compile-time checking

---

## 🎨 MVVM Pattern

### View Layer

Views hanya untuk presentation, tidak ada business logic:

```swift
struct ExamCodeInputView: View {
    @StateObject var viewModel: ExamCodeInputViewModel

    init(viewModel: ExamCodeInputViewModel, ...) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        // Only UI code, no business logic
        GlassButton(
            title: viewModel.isLoading ? "Validating..." : "Start Exam",
            action: {
                Task { await viewModel.validateCode() }
            }
        )
    }
}
```

### ViewModel Layer

ViewModels berisi semua business logic:

```swift
@MainActor
final class ExamCodeInputViewModel: ObservableObject {
    @Published var examCode: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let apiService: ExamAPIServiceProtocol

    init(apiService: ExamAPIServiceProtocol) {
        self.apiService = apiService
    }

    func validateCode() async {
        // Business logic here
        isLoading = true
        let response = try await apiService.resolveExamCode(examCode)
        // ...
    }
}
```

### Model Layer

Models sebagai data containers:

```swift
class ExamSession: ObservableObject {
    @Published var examId: String
    @Published var examUrl: String
    @Published var examTitle: String
    @Published var duration: Int
    @Published var lockMode: Bool

    func start() { /* state management */ }
    func end() { /* state management */ }
}
```

---

## ⚙️ Configuration Management

### AppConfiguration

Centralized configuration untuk semua app settings:

```swift
struct AppConfiguration {
    struct API {
        static let baseURL = "https://api.margasatya.com"
        static let timeout: TimeInterval = 30
    }

    struct Assessment {
        static let defaultAdminPIN = "1234"
        static let tripleTapWindow: TimeInterval = 2.0
    }

    struct Features {
        static var isDevelopmentMode = true
        static let adminOverrideEnabled = true
        static let hapticFeedbackEnabled = true
    }
}
```

### UIConstants

Design tokens untuk consistent UI:

```swift
enum UIConstants {
    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let regular: CGFloat = 16
        static let large: CGFloat = 20
        static let extraLarge: CGFloat = 24
    }

    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let regular: CGFloat = 16
        static let card: CGFloat = 24
    }
}
```

**Benefits:**
- ✅ No magic numbers
- ✅ Consistent design
- ✅ Easy to update theme
- ✅ Type-safe constants

---

## 📱 Native SwiftUI Components

### Before (Hardcoded)

```swift
Text("Hello")
    .foregroundColor(.white)        // Deprecated
    .padding(16)                     // Magic number
```

### After (Native + Constants)

```swift
Text("Hello")
    .foregroundStyle(.white)         // Native SwiftUI
    .padding(UIConstants.Spacing.regular)
```

### Native Components Used:

- `foregroundStyle()` instead of `foregroundColor()`
- `imageScale()` for SF Symbols
- `.ultraThinMaterial` for native glass effect
- `TextField` with native placeholders
- Native `Button` styling
- `@StateObject` for ownership
- `@ObservedObject` for observation

---

## 🧪 Testability

### Before (Not Testable)

```swift
class ExamCodeInputViewModel {
    private let apiService = ExamAPIService.shared // Singleton!
}
```

**Problem:** Tidak bisa inject mock service untuk testing

### After (Testable)

```swift
class ExamCodeInputViewModel {
    private let apiService: ExamAPIServiceProtocol // Protocol!

    init(apiService: ExamAPIServiceProtocol) {
        self.apiService = apiService
    }
}

// In tests:
let mockAPI = MockExamAPIService()
let viewModel = ExamCodeInputViewModel(apiService: mockAPI)
```

**Benefits:**
- ✅ Unit testable
- ✅ Mockable dependencies
- ✅ Isolated testing
- ✅ Fast tests (no network calls)

---

## 📁 Project Structure

```
MargaSatya/
├── Sources/
│   ├── Core/
│   │   ├── Configuration/
│   │   │   ├── AppConfiguration.swift
│   │   │   └── UIConstants.swift
│   │   ├── Protocols/
│   │   │   ├── ExamAPIServiceProtocol.swift
│   │   │   └── AssessmentModeServiceProtocol.swift
│   │   └── DependencyInjection/
│   │       └── DIContainer.swift
│   ├── Features/
│   │   ├── ExamCodeInput/
│   │   │   ├── ExamCodeInputView.swift
│   │   │   └── ExamCodeInputViewModel.swift
│   │   ├── ExamSessionPreparation/
│   │   │   ├── ExamPreparationView.swift
│   │   │   └── ExamPreparationViewModel.swift
│   │   ├── SecureExamWebView/
│   │   │   ├── SecureExamView.swift
│   │   │   └── SecureExamViewModel.swift
│   │   └── ExamCompleted/
│   │       └── ExamCompletedView.swift
│   ├── Services/
│   │   ├── ExamAPIService.swift
│   │   ├── AssessmentModeManager.swift
│   │   └── SecureWebViewCoordinator.swift
│   ├── Models/
│   │   ├── ExamSession.swift
│   │   └── ExamResponse.swift
│   └── UIComponents/
│       ├── GlassBackground.swift
│       └── GlassCard.swift
├── ContentView.swift
└── MargaSatyaApp.swift
```

---

## 🔄 Data Flow

```
User Input
    ↓
View (ExamCodeInputView)
    ↓ action
ViewModel (ExamCodeInputViewModel.validateCode())
    ↓ call
Service (ExamAPIService.resolveExamCode())
    ↓ network
API Backend
    ↓ response
Service (ExamResponse)
    ↓ parse
ViewModel (update @Published properties)
    ↓ binding
View (UI update automatically)
```

---

## ✅ Best Practices Implemented

### Clean Code:
- ✅ Descriptive naming
- ✅ MARK comments for organization
- ✅ Single responsibility functions
- ✅ DRY (Don't Repeat Yourself)
- ✅ No magic numbers/strings
- ✅ Proper error handling

### SwiftUI Best Practices:
- ✅ Native components
- ✅ @StateObject ownership
- ✅ @ObservedObject for passed objects
- ✅ ViewBuilder pattern
- ✅ Computed properties for views
- ✅ Environment for shared data

### Architecture:
- ✅ MVVM pattern
- ✅ SOLID principles
- ✅ Dependency injection
- ✅ Protocol-oriented programming
- ✅ Separation of concerns
- ✅ Testable architecture

---

## 🚀 Future Improvements

### Completed ✅
- [x] Protocol-based services
- [x] Dependency injection
- [x] ViewModels for all views
- [x] Configuration management
- [x] Native SwiftUI components
- [x] UIConstants for design tokens

### In Progress 🔄
- [ ] Complete SecureExamView refactoring (move timer to ViewModel)
- [ ] Unit tests for ViewModels
- [ ] Unit tests for Services

### Planned 📋
- [ ] Coordinator pattern for navigation
- [ ] Repository pattern for data layer
- [ ] Use case layer for complex business logic
- [ ] Environment injection for SwiftUI
- [ ] Snapshot testing for UI
- [ ] Integration tests
- [ ] CI/CD pipeline

---

## 📖 How to Use

### Creating a View with ViewModel:

```swift
// 1. Get ViewModel from DIContainer
let viewModel = DIContainer.shared.makeExamCodeInputViewModel()

// 2. Pass to View
ExamCodeInputView(
    viewModel: viewModel,
    examSession: $examSession,
    shouldPrepareExam: $shouldPrepareExam
)
```

### Adding a New Feature:

1. **Create Protocol** (if new service needed)
2. **Implement Service** conforming to protocol
3. **Create ViewModel** with protocol dependency
4. **Create View** using ViewModel
5. **Update DIContainer** with factory method
6. **Add Configuration** if needed

---

## 🎓 Learning Resources

- [SOLID Principles in Swift](https://www.swiftbysundell.com/articles/solid-swift/)
- [MVVM in SwiftUI](https://www.hackingwithswift.com/books/ios-swiftui/introducing-mvvm-into-your-swiftui-project)
- [Dependency Injection in Swift](https://www.avanderlee.com/swift/dependency-injection/)
- [Protocol-Oriented Programming](https://developer.apple.com/videos/play/wwdc2015/408/)

---

**Authored by:** Claude (Anthropic)
**Version:** 2.0
**Last Updated:** November 2025
