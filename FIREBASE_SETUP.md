# Firebase Setup untuk MargaSatya

Panduan lengkap untuk setup Firebase Firestore dan Authentication untuk MargaSatya.

---

## 📋 Prerequisites

- **Firebase Account** (gratis di [Firebase Console](https://console.firebase.google.com))
- **Xcode 15+** terpasang
- **iOS 15+** deployment target
- **Bundle Identifier** sudah ditentukan (e.g., `com.yourcompany.secureexamid`)

---

## 🚀 Step 1: Buat Firebase Project

### 1.1 Create Project

1. Buka [Firebase Console](https://console.firebase.google.com)
2. Klik **Add Project** atau **Create a project**
3. **Project Name:** `MargaSatya` (atau nama lain)
4. **Google Analytics:** Optional (bisa disable untuk simplicity)
5. Klik **Create Project**

### 1.2 Register iOS App

1. Di Firebase Console, klik ikon **iOS** untuk add iOS app
2. **Bundle ID:** Gunakan bundle ID yang sama dengan Xcode project
   - Untuk mendapatkan bundle ID:
     - Buka Xcode → Target MargaSatya → General → Identity → Bundle Identifier
     - Contoh: `com.margasatya.secureexamid`
3. **App Nickname:** MargaSatya (optional)
4. **App Store ID:** Kosongkan (optional, untuk production nanti)
5. Klik **Register App**

### 1.3 Download GoogleService-Info.plist

1. Klik **Download GoogleService-Info.plist**
2. Save file ke folder project Anda
3. **PENTING:** Jangan commit file ini ke Git (sudah ada di .gitignore)

---

## 📦 Step 2: Install Firebase SDK

### 2.1 Via Swift Package Manager (Recommended)

1. Buka `MargaSatya.xcodeproj` di Xcode
2. **File** → **Add Package Dependencies...**
3. Masukkan URL:
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```
4. **Dependency Rule:** Up to Next Major Version - **10.20.0** (atau terbaru)
5. Klik **Add Package**
6. Select packages yang diperlukan:
   - ✅ **FirebaseAuth** (Authentication)
   - ✅ **FirebaseFirestore** (Database)
   - ✅ **FirebaseFirestoreSwift** (Codable support)
7. Klik **Add Package**

### 2.2 Tambahkan GoogleService-Info.plist ke Project

1. Drag & drop `GoogleService-Info.plist` ke Xcode navigator
2. **Destination:** Pastikan "Copy items if needed" ✅ DICENTANG
3. **Add to targets:** Centang "MargaSatya"
4. Lokasi file seharusnya:
   ```
   MargaSatya/MargaSatya/GoogleService-Info.plist
   ```

### 2.3 Verifikasi Installation

Build project (`Cmd + B`). Jika ada error:
- Clean build folder: `Cmd + Shift + K`
- Rebuild: `Cmd + B`

---

## ⚙️ Step 3: Initialize Firebase

Firebase sudah di-initialize di `MargaSatyaApp.swift`. Verifikasi code:

```swift
import SwiftUI
import FirebaseCore

@main
struct MargaSatyaApp: App {

    init() {
        // Initialize Firebase
        FirebaseApp.configure()

        // Initialize encryption service
        do {
            try DIContainer.shared.encryptionService.ensureEncryptionKeyExists()
        } catch {
            print("⚠️ Failed to initialize encryption: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RoleSelectionView()
        }
    }
}
```

**Test:** Run app di simulator. Check console untuk:
```
[Firebase/Core][I-COR000003] The default Firebase app has been configured.
```

Jika muncul log ini, Firebase configured successfully! ✅

---

## 🔐 Step 4: Enable Firebase Authentication

### 4.1 Enable Email/Password Sign-in

1. Di Firebase Console, pilih project Anda
2. Sidebar kiri → **Build** → **Authentication**
3. Klik **Get Started** (jika baru pertama kali)
4. Tab **Sign-in method**
5. Klik **Email/Password**
6. **Enable** toggle → Aktifkan
7. **Email link (passwordless sign-in)** → Tidak perlu diaktifkan
8. Klik **Save**

### 4.2 Create Admin User (Manual via Console)

**IMPORTANT:** Admin account harus dibuat manual karena memerlukan admin key validation.

1. Di Firebase Console → **Authentication** → Tab **Users**
2. Klik **Add user**
3. **Email:** `admin@example.com` (atau email admin Anda)
4. **Password:** `admin123456` (gunakan password yang kuat untuk production!)
5. Klik **Add user**
6. **Copy User UID** (akan digunakan di langkah berikutnya)

---

## 🗄️ Step 5: Setup Firestore Database

### 5.1 Create Firestore Database

1. Di Firebase Console, sidebar kiri → **Build** → **Firestore Database**
2. Klik **Create database**
3. **Location:** Pilih lokasi terdekat (e.g., `asia-southeast1` untuk Indonesia)
4. **Security rules:** Pilih **Start in production mode** (kita akan update rules manual)
5. Klik **Next** → **Enable**

### 5.2 Create Initial Collections & Documents

#### A. Create `users` Collection dengan Admin Document

1. Klik **Start collection**
2. **Collection ID:** `users`
3. **Document ID:** Paste **User UID** dari Authentication (langkah 4.2)
4. **Fields:**
   ```
   Field name        | Field type | Value
   ----------------- | ---------- | ------------------
   name              | string     | Super Admin
   email             | string     | admin@example.com
   role              | string     | ADMIN
   authUID           | string     | <Paste User UID>
   createdAt         | timestamp  | <Click to set now>
   isActive          | boolean    | true
   ```
5. Klik **Save**

#### B. Create `appConfig` Collection

1. Klik **Start collection**
2. **Collection ID:** `appConfig`
3. **Document ID:** `settings`
4. **Fields:**
   ```
   Field name        | Field type | Value
   ----------------- | ---------- | -------------
   maintenanceMode   | boolean    | false
   minAppVersion     | string     | 1.0
   adminKey          | string     | ADMIN_KEY_2025
   ```
5. Klik **Save**

**Note:** `adminKey` di atas adalah contoh. Untuk production, gunakan key yang kuat dan hash dengan SHA-256.

### 5.3 Update Firestore Security Rules

1. Di Firestore Console → Tab **Rules**
2. Replace dengan rules berikut:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function getUserData() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }

    function isAdmin() {
      return isAuthenticated() && getUserData().role == 'ADMIN';
    }

    function isTeacher() {
      return isAuthenticated() && getUserData().role == 'GURU';
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Users collection
    match /users/{userId} {
      // Anyone can read their own user document
      allow read: if isOwner(userId);

      // Teachers can read all users (for participant selection)
      allow read: if isTeacher();

      // Admins can read all users
      allow read: if isAdmin();

      // Users can update their own document
      allow update: if isOwner(userId);

      // New users can create their own document during registration
      allow create: if isOwner(userId) || isAdmin();
    }

    // Students collection
    match /students/{studentId} {
      // Teachers can read all students
      allow read: if isTeacher() || isAdmin();

      // Only teachers can create/update/delete students
      allow create, update: if isTeacher();
      allow delete: if isTeacher();
    }

    // Exams collection
    match /exams/{examId} {
      // Teachers and admins can read all exams
      allow read: if isTeacher() || isAdmin();

      // Only teachers can create/update/delete exams
      allow create, update: if isTeacher();
      allow delete: if isTeacher();

      // Questions subcollection
      match /questions/{questionId} {
        allow read: if isTeacher() || isAdmin();
        allow write: if isTeacher();
      }

      // Participants subcollection
      match /participants/{participantId} {
        allow read: if isTeacher() || isAdmin();
        allow write: if isTeacher();
      }
    }

    // Exam sessions collection
    match /examSessions/{sessionId} {
      // Teachers and admins can read all sessions
      allow read: if isTeacher() || isAdmin();

      // Anyone can create/update session (students tidak punya auth)
      // Di production, tambahkan validasi tambahan (e.g., NIS + accessCode)
      allow create, update: if true;

      // Answers subcollection
      match /answers/{answerId} {
        // Teachers can read answers (untuk grading)
        allow read: if isTeacher() || isAdmin();

        // Anyone can write answers (students)
        allow write: if true;
      }
    }

    // App config collection
    match /appConfig/{configId} {
      // Anyone can read config
      allow read: if true;

      // Only admins can write config
      allow write: if isAdmin();
    }
  }
}
```

3. Klik **Publish**

⚠️ **IMPORTANT - Security Note:**

Rules di atas mengizinkan students (tanpa auth) untuk create/update sessions dan answers. Ini sesuai requirement bahwa students tidak perlu register. Untuk production, consider:
- Server-side validation untuk NIS + accessCode
- Rate limiting
- Firebase App Check untuk prevent abuse

### 5.4 Create Indexes (Optional but Recommended)

Firebase akan otomatis suggest indexes saat Anda run queries yang perlu index. Atau, buat manual:

1. Firestore Console → Tab **Indexes**
2. Klik **Create Index**

**Recommended Indexes:**

**Index 1: Students by Teacher**
- **Collection:** `students`
- **Fields:**
  - `teacherId` (Ascending)
  - `isActive` (Ascending)
  - `createdAt` (Descending)
- **Query scope:** Collection

**Index 2: Exams by Teacher**
- **Collection:** `exams`
- **Fields:**
  - `teacherId` (Ascending)
  - `isActive` (Ascending)
  - `createdAt` (Descending)
- **Query scope:** Collection

**Index 3: Sessions by Exam**
- **Collection:** `examSessions`
- **Fields:**
  - `examId` (Ascending)
  - `status` (Ascending)
  - `startedAt` (Descending)
- **Query scope:** Collection

---

## ✅ Step 6: Verify Setup

### 6.1 Test Firebase Connection

1. Run app di simulator atau device
2. Check console logs:
   ```
   [Firebase/Core][I-COR000003] The default Firebase app has been configured.
   ```

### 6.2 Test Authentication

1. Launch app → Select **"Guru"**
2. Tab **"Daftar"** (Register)
3. Input:
   - Nama: `Test Teacher`
   - Email: `teacher@test.com`
   - Password: `password123`
4. Tap **Daftar**
5. Jika berhasil → Navigate ke TeacherHomeView ✅

**Verify di Firebase Console:**
- Authentication → Users → Should see `teacher@test.com`
- Firestore → `users` collection → Should see new teacher document

### 6.3 Test Firestore CRUD

**Create Student:**
1. Di Teacher dashboard → Tap **Kelola Siswa**
2. Tap **+** untuk add student
3. Input:
   - Nama: `Test Student`
   - NIS: `12345`
4. Tap **Simpan**

**Verify di Firestore:**
- Firestore Console → `students` collection → Should see new student document

If all above works, Firebase setup is **COMPLETE!** 🎉

---

## 🔧 Configuration Details

### Firebase SDK Versions (Tested)

```swift
// Tested with:
- Firebase iOS SDK: 10.20.0+
- Swift: 5.9+
- iOS: 15.0+
```

### Firestore Collection Structure

```
firestore/
├── users/                          # User accounts (3 roles)
│   └── {userId}                    # Document ID = Firebase Auth UID
│       ├── name: string
│       ├── email: string
│       ├── role: "ADMIN" | "GURU" | "SISWA"
│       ├── authUID: string
│       ├── createdAt: timestamp
│       └── isActive: boolean
│
├── students/                       # Students managed by teachers
│   └── {studentId}                 # Auto-generated ID
│       ├── name: string
│       ├── nis: string (unique per teacher)
│       ├── teacherId: string (ref to users)
│       ├── createdAt: timestamp
│       └── isActive: boolean
│
├── exams/                          # Exams created by teachers
│   └── {examId}
│       ├── title: string
│       ├── description: string
│       ├── type: "GOOGLE_FORM" | "IN_APP"
│       ├── formUrl: string? (only for GOOGLE_FORM)
│       ├── accessCode: string (unique)
│       ├── teacherId: string
│       ├── startTime: timestamp?
│       ├── endTime: timestamp?
│       ├── createdAt: timestamp
│       ├── isActive: boolean
│       │
│       ├── questions/              # Subcollection (only for IN_APP)
│       │   └── {questionId}
│       │       ├── questionText: string
│       │       ├── type: "MULTIPLE_CHOICE" | "ESSAY"
│       │       ├── options: [string]?
│       │       ├── correctAnswer: string?
│       │       ├── points: number
│       │       └── order: number
│       │
│       └── participants/           # Subcollection
│           └── {participantId}
│               ├── studentId: string
│               ├── nis: string
│               ├── studentName: string
│               └── hasAccess: boolean
│
├── examSessions/                   # Active/past exam sessions
│   └── {sessionId}
│       ├── examId: string
│       ├── studentId: string (placeholder for non-auth students)
│       ├── nis: string
│       ├── status: "NOT_STARTED" | "IN_PROGRESS" | "SUBMITTED" | "SUBMISSION_PENDING"
│       ├── startedAt: timestamp?
│       ├── submittedAt: timestamp?
│       ├── currentQuestionIndex: number?
│       ├── answeredQuestionIds: [string]?
│       │
│       └── answers/                # Subcollection
│           └── {answerId}
│               ├── questionId: string
│               ├── answerText: string (ENCRYPTED)
│               ├── answeredAt: timestamp
│               └── encryptionMetadata: map {
│                   ├── algorithm: string
│                   ├── iv: string (Base64)
│                   ├── tag: string (Base64)
│                   └── timestamp: timestamp
│                 }
│
└── appConfig/                      # App-wide configuration
    └── settings
        ├── maintenanceMode: boolean
        ├── minAppVersion: string
        └── adminKey: string
```

### Service Imports

Pastikan semua service files import Firebase dengan benar:

```swift
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
```

---

## 🐛 Troubleshooting

### Error: "The default Firebase app has not yet been configured"

**Cause:** `FirebaseApp.configure()` belum dipanggil

**Solution:**
1. Check `MargaSatyaApp.swift` → `init()` method
2. Pastikan `FirebaseApp.configure()` dipanggil SEBELUM apapun
3. Pastikan `GoogleService-Info.plist` ada di main bundle

### Error: "Could not reach Cloud Firestore backend"

**Cause:** Network issues atau Firestore belum enabled

**Solutions:**
1. Check internet connection
2. Verify Firestore Database sudah dibuat di Firebase Console
3. Check Firestore rules (pastikan tidak terlalu restrictive)
4. Try restart app

### Error: "Missing or insufficient permissions"

**Cause:** Firestore rules blocking request

**Solutions:**
1. Check Firestore Console → Rules
2. Verify user role di `users` collection
3. Check `authUID` field matches Firebase Auth UID
4. Temporarily set rules ke test mode untuk debug:
   ```javascript
   allow read, write: if true; // ⚠️ ONLY FOR TESTING
   ```

### Error: "Unable to fetch document: [code=permission-denied]"

**Cause:** User document tidak ada di Firestore atau role tidak valid

**Solutions:**
1. Check `users` collection → Verify user document exists
2. Verify `authUID` field matches user's Firebase Auth UID
3. Check `role` field = "ADMIN" / "GURU" / "SISWA"
4. Verify user is authenticated (check `Auth.auth().currentUser`)

### Error: "Query requires an index"

**Cause:** Firestore query needs composite index

**Solutions:**
1. Firebase akan log URL untuk create index → Click link
2. Or create manual di Firestore Console → Indexes
3. Wait ~2-5 minutes for index to build
4. Retry query

### Build Error: "No such module 'FirebaseFirestore'"

**Cause:** Firebase SDK tidak ter-link dengan benar

**Solutions:**
1. Clean build folder: `Cmd + Shift + K`
2. Delete derived data: `Xcode → Preferences → Locations → Derived Data → Delete`
3. Remove Firebase packages: Xcode → Project → Package Dependencies → Remove all
4. Re-add Firebase packages via SPM (langkah 2.1)
5. Rebuild: `Cmd + B`

### App Crashes on Launch

**Cause:** GoogleService-Info.plist salah atau bundle ID tidak match

**Solutions:**
1. Verify `GoogleService-Info.plist` di main bundle (not in subfolder)
2. Check bundle ID di `GoogleService-Info.plist`:
   ```xml
   <key>BUNDLE_ID</key>
   <string>com.yourcompany.secureexamid</string>
   ```
3. Compare dengan Xcode bundle ID (harus sama persis!)
4. If bundle ID changed, download new `GoogleService-Info.plist` dari Firebase Console

### Authentication: "Email already in use"

**Cause:** Email sudah terdaftar

**Solutions:**
1. Gunakan email berbeda
2. Or delete user di Firebase Console → Authentication → Users
3. Or implement "Forgot Password" flow

### Firestore: "DEADLINE_EXCEEDED" errors

**Cause:** Network slow atau Firestore quota exceeded

**Solutions:**
1. Check internet speed
2. Firebase Console → Usage → Verify tidak exceed quota
3. Implement retry logic (already in NetworkMonitor)
4. Increase timeout di Firestore settings:
   ```swift
   let settings = Firestore.firestore().settings
   settings.dispatchQueue = DispatchQueue.global(qos: .background)
   Firestore.firestore().settings = settings
   ```

---

## 🧪 Testing Firebase Setup

### Quick Test Script

Tambahkan test button di `RoleSelectionView.swift` (temporary):

```swift
Button("Test Firebase") {
    Task {
        await testFirebase()
    }
}

func testFirebase() async {
    print("🔥 Testing Firebase...")

    // Test 1: Firestore connection
    do {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("appConfig").document("settings").getDocument()
        print("✅ Firestore: Connected")
        print("   Config: \(snapshot.data() ?? [:])")
    } catch {
        print("❌ Firestore: \(error)")
    }

    // Test 2: Authentication
    do {
        let result = try await Auth.auth().signIn(withEmail: "admin@example.com", password: "admin123456")
        print("✅ Auth: Logged in as \(result.user.email ?? "")")

        // Test 3: Fetch user document
        let db = Firestore.firestore()
        let userDoc = try await db.collection("users").document(result.user.uid).getDocument()
        print("✅ User: \(userDoc.data()?["name"] ?? "Unknown")")
        print("   Role: \(userDoc.data()?["role"] ?? "Unknown")")
    } catch {
        print("❌ Auth: \(error)")
    }
}
```

Run app → Tap "Test Firebase" → Check console for results.

---

## 🔒 Security Best Practices

### Production Checklist

Before deploying to production:

- [ ] **Change default admin password** dari `admin123456` ke strong password
- [ ] **Update adminKey** di `appConfig/settings` dengan key yang di-hash (SHA-256)
- [ ] **Review Firestore rules** - Pastikan tidak terlalu permissive
- [ ] **Enable Firebase App Check** untuk prevent abuse
- [ ] **Setup Firebase Security Rules tests** untuk CI/CD
- [ ] **Enable Firestore backups** di Firebase Console
- [ ] **Setup monitoring** (Firebase Crashlytics)
- [ ] **Implement rate limiting** untuk prevent spam
- [ ] **Add logging** untuk security events
- [ ] **Review data export** requirements (GDPR compliance)

### Firestore Rules Testing

Test rules di Firebase Console → Rules Playground:

```javascript
// Test: Teacher can read own students
Service: cloud.firestore
Path: /students/student123
Request type: get
Auth UID: <teacher_auth_uid>
Expected result: Allow
```

---

## 📊 Monitoring & Analytics

### Enable Firebase Analytics (Optional)

1. Firebase Console → Analytics
2. Enable Analytics untuk your project
3. Tambahkan `FirebaseAnalytics` di SPM dependencies
4. Import di `MargaSatyaApp.swift`:
   ```swift
   import FirebaseAnalytics
   ```
5. Log events:
   ```swift
   Analytics.logEvent("exam_started", parameters: ["exam_id": examId])
   ```

### Enable Crashlytics (Recommended for Production)

1. Firebase Console → Crashlytics → Get Started
2. Add `FirebaseCrashlytics` di SPM
3. Follow setup instructions
4. Crashes akan otomatis ter-report

---

## 🌍 Multi-Environment Setup (Optional)

Untuk development vs production:

### Development Environment

1. Create separate Firebase project: `MargaSatya-Dev`
2. Download `GoogleService-Info-Dev.plist`
3. Use build configurations di Xcode:
   ```swift
   #if DEBUG
   let plistName = "GoogleService-Info-Dev"
   #else
   let plistName = "GoogleService-Info"
   #endif
   ```

### Firestore Emulator (Local Development)

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Init project
firebase init firestore

# Start emulator
firebase emulators:start --only firestore
```

Update code untuk use emulator:

```swift
#if DEBUG
let settings = Firestore.firestore().settings
settings.host = "localhost:8080"
settings.isSSLEnabled = false
Firestore.firestore().settings = settings
#endif
```

---

## 📚 Resources

- **Firebase Documentation:** https://firebase.google.com/docs/ios/setup
- **Firestore Documentation:** https://firebase.google.com/docs/firestore
- **Firebase Auth Documentation:** https://firebase.google.com/docs/auth
- **Security Rules Guide:** https://firebase.google.com/docs/firestore/security/get-started
- **Best Practices:** https://firebase.google.com/docs/firestore/best-practices

---

## ✅ Setup Complete!

Jika semua langkah di atas selesai:

- ✅ Firebase project created
- ✅ Firebase SDK installed
- ✅ GoogleService-Info.plist added
- ✅ Authentication enabled (Email/Password)
- ✅ Firestore database created
- ✅ Security rules configured
- ✅ Initial collections & documents created
- ✅ Admin account created
- ✅ Connection tested

**You're ready to build! 🚀**

Lanjut ke [README.md](README.md) untuk development guidelines atau [DEPLOYMENT.md](DEPLOYMENT.md) untuk production deployment.

---

**Last Updated:** 2025-11-17
**Firebase iOS SDK Version:** 10.20.0+
**Status:** ✅ Production Ready
