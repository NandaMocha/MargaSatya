# MargaSatya - iOS Secure Exam Browser

**Version:** 1.0
**Platform:** iOS 15+
**Tech Stack:** Swift 5+, SwiftUI, Automatic Assessment Configuration (AAC)

---

## 📱 Overview

MargaSatya adalah aplikasi secure exam browser untuk iOS yang memungkinkan siswa mengikuti ujian dalam mode terkunci menggunakan Google Form. Aplikasi ini menggunakan **Automatic Assessment Configuration (AAC)** dari Apple untuk mengunci device selama ujian berlangsung.

### Key Features

- ✅ **Code-Based Access** - Siswa memasukkan kode ujian untuk mengakses
- 🔒 **Assessment Mode (AAC)** - Device terkunci penuh selama ujian
- 🌐 **Google Form Integration** - Ujian ditampilkan melalui WebView
- 💎 **Liquid Glass UI** - Interface modern dengan glassmorphic design
- ⏱️ **Timer & Auto-Submit** - Countdown timer dengan auto-submit
- 🛡️ **Security Features** - Disable screenshot, multitasking, notifications

---

## 🏗️ Project Structure

```
MargaSatya/
├── Sources/
│   ├── Features/
│   │   ├── ExamCodeInput/          # Home screen - input kode ujian
│   │   ├── ExamSessionPreparation/ # Preparation screen sebelum mulai
│   │   ├── SecureExamWebView/      # WebView screen untuk ujian
│   │   └── ExamCompleted/          # Completion screen
│   ├── Services/
│   │   ├── AssessmentModeManager.swift      # AAC manager
│   │   ├── ExamAPIService.swift             # API service
│   │   └── SecureWebViewCoordinator.swift   # WebView coordinator
│   ├── Models/
│   │   ├── ExamSession.swift       # Exam session model
│   │   └── ExamResponse.swift      # API response model
│   └── UIComponents/
│       ├── GlassBackground.swift   # Animated liquid glass background
│       └── GlassCard.swift         # Glassmorphic UI components
├── ContentView.swift               # Main navigation controller
└── MargaSatyaApp.swift            # App entry point
```

---

## 🚀 Setup Instructions

### 1. Requirements

- **Xcode 15+**
- **iOS 15+** deployment target
- **Apple Developer Account** (untuk AAC entitlement)
- **Device/Simulator** yang support AAC

### 2. Xcode Configuration

#### A. Add Entitlements File

1. Buka project di Xcode
2. File `MargaSatya.entitlements` sudah dibuat
3. Di Xcode, pilih Target **MargaSatya**
4. Pergi ke **Signing & Capabilities**
5. Klik **+ Capability** → Add **Automatic Assessment Configuration**
6. Pastikan entitlement file terhubung di **Build Settings** → **Code Signing Entitlements**

#### B. Info.plist Configuration

Tambahkan key berikut ke Info.plist (atau Project Settings → Info):

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>docs.google.com</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
            <false/>
        </dict>
        <key>accounts.google.com</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>

<key>UIStatusBarHidden</key>
<false/>

<key>UIViewControllerBasedStatusBarAppearance</key>
<true/>
```

#### C. Request AAC Entitlement from Apple

AAC memerlukan approval dari Apple:

1. Login ke [Apple Developer Portal](https://developer.apple.com/)
2. Pergi ke **Certificates, Identifiers & Profiles**
3. Pilih App ID untuk MargaSatya
4. Enable **Automatic Assessment Configuration**
5. Submit request (biasanya diapprove otomatis untuk education apps)

### 3. Build & Run

```bash
# Open project
cd MargaSatya
open MargaSatya.xcodeproj

# Select target device (iOS 15+)
# Build: Cmd + B
# Run: Cmd + R
```

---

## 🔧 Configuration

### Backend API Setup

Aplikasi menggunakan API untuk validasi kode ujian. Edit `ExamAPIService.swift`:

```swift
private let baseURL = "https://api.margasatya.com"
```

**API Endpoint:**

```
POST /exam/resolve-code
Content-Type: application/json

Request:
{
  "code": "ABC123"
}

Response:
{
  "examId": "EX001",
  "examUrl": "https://docs.google.com/forms/d/e/...",
  "examTitle": "Ujian Akhir Semester",
  "duration": 60,
  "lockMode": true
}
```

### Mock Mode (Development)

Untuk testing tanpa backend, aplikasi sudah menggunakan `mockResolveExamCode()`. Untuk production, ganti di `ExamCodeInputViewModel.swift`:

```swift
// Development (mock)
let response = try await apiService.mockResolveExamCode(code)

// Production (real API)
let response = try await apiService.resolveExamCode(code)
```

---

## 🎨 UI/UX Features

### Liquid Glass Design

- **GlassBackground**: Animated gradient background dengan floating blobs
- **GlassCard**: Glassmorphic card dengan blur effect
- **GlassButton**: Button dengan gradient dan glass effect
- **GlassTextField**: Input field dengan glass styling

### Screens Flow

1. **Exam Code Input** → Input kode ujian
2. **Exam Preparation** → Review ujian info & instruksi
3. **Secure Exam** → WebView dalam assessment mode
4. **Exam Completed** → Success screen dengan animation

---

## 🔒 Security Features

### Automatic Assessment Configuration (AAC)

Ketika exam dimulai dengan `lockMode: true`:

- ❌ **No multitasking** - User tidak bisa switch app
- ❌ **No Control Center** - Swipe dari bawah disabled
- ❌ **No Notification Center** - Swipe dari atas disabled
- ❌ **No screenshots** - Screen capture disabled
- ❌ **No screen recording** - Recording disabled
- ❌ **No split-screen** (iPad) - Multitasking disabled
- ❌ **No Home button** - Keluar app tidak mungkin

### WebView Security

- Private browsing (no cache)
- Domain whitelist (hanya Google Forms)
- Disable copy/paste (except input fields)
- Disable context menu
- Disable new window/tab
- Intercept external links

### Admin Override

Triple-tap di layar exam → Admin PIN (default: `1234`)

---

## 🧪 Testing

### Test Code Input

Masukkan kode ujian apa saja (min 3 karakter) untuk mock mode.

### Test Assessment Mode

⚠️ **Important:** AAC hanya berfungsi di:
- Device fisik (tidak di semua simulator)
- iOS 13.4+
- Dengan entitlement yang valid

Jika AAC gagal start, aplikasi akan menampilkan error alert.

### Test Google Form

Gunakan Google Form publik untuk testing:
- Buat form di Google Forms
- Set "Get link" → Copy link
- Return link di API response sebagai `examUrl`

---

## 📋 TODO & Future Improvements

- [ ] **Proctoring** - Camera monitoring
- [ ] **Analytics** - Track exam behavior
- [ ] **Offline Support** - Cache exam untuk offline
- [ ] **MDM Integration** - Enterprise device management
- [ ] **Backend Dashboard** - Admin panel untuk manage exams
- [ ] **Biometric Lock** - Face ID/Touch ID untuk admin override
- [ ] **Session Recording** - Log exam events

---

## 🐛 Troubleshooting

### Assessment Mode Not Starting

**Error:** "Your device does not support secure exam mode"

**Solutions:**
1. Pastikan menggunakan device fisik (bukan simulator lama)
2. Check AAC entitlement di developer portal
3. Rebuild app dengan provisioning profile yang benar
4. Pastikan iOS 13.4+

### WebView Not Loading

**Error:** "Failed to load exam"

**Solutions:**
1. Check internet connection
2. Verify Google Form URL is valid
3. Check ATS (App Transport Security) settings
4. Ensure domain is whitelisted in `SecureWebViewCoordinator.swift`

### Build Errors

**Error:** "Code signing entitlements file not found"

**Solution:**
1. Pergi ke Target → Build Settings
2. Search "Code Signing Entitlements"
3. Set path: `MargaSatya/MargaSatya.entitlements`

---

## 📄 License

Copyright © 2025 MargaSatya. All rights reserved.

---

## 👥 Support

Untuk bantuan atau pertanyaan, hubungi tim development.

---

**Built with ❤️ using Swift & SwiftUI**
