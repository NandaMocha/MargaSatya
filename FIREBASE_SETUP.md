# Firebase Setup untuk SecureExamID

## 1. Tambahkan Firebase SDK

### Via Swift Package Manager (Recommended)

1. Buka `MargaSatya.xcodeproj` di Xcode
2. File → Add Package Dependencies
3. Masukkan URL: `https://github.com/firebase/firebase-ios-sdk`
4. Pilih versi: **10.20.0** atau yang terbaru
5. Pilih packages yang diperlukan:
   - ✅ **FirebaseFirestore** (required)
   - ✅ **FirebaseAuth** (required)
   - ✅ **FirebaseFirestoreSwift** (required)

### Import di File Swift

```swift
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
```

## 2. Tambahkan GoogleService-Info.plist

### Langkah-langkah:

1. **Buat Firebase Project** di [Firebase Console](https://console.firebase.google.com)
   - Nama project: `SecureExamID` atau sesuai keinginan
   - Platform: iOS

2. **Register iOS App:**
   - Bundle ID: Sesuaikan dengan bundle ID Xcode project
   - Contoh: `com.margasatya.secureexamid`

3. **Download GoogleService-Info.plist**
   - Download file dari Firebase Console
   - Drag & drop ke Xcode project
   - ⚠️ **PENTING:** Pastikan "Copy items if needed" dicentang
   - Target: MargaSatya

4. **Letakkan di lokasi:**
   ```
   MargaSatya/MargaSatya/GoogleService-Info.plist
   ```

## 3. Initialize Firebase di App

File `MargaSatyaApp.swift` atau `SecureExamIDApp.swift`:

```swift
import SwiftUI
import FirebaseCore

@main
struct SecureExamIDApp: App {
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RoleSelectionView()
                .environmentObject(DIContainer.shared)
        }
    }
}
```

## 4. Konfigurasi Firestore

### Security Rules (di Firebase Console)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Students collection
    match /students/{studentId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'GURU';
    }

    // Exams collection
    match /exams/{examId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'GURU';

      // Questions subcollection
      match /questions/{questionId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null &&
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'GURU';
      }

      // Participants subcollection
      match /participants/{participantId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null &&
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'GURU';
      }
    }

    // Exam sessions
    match /examSessions/{sessionId} {
      allow read: if request.auth != null;
      allow create: if true; // Siswa bisa create session tanpa auth
      allow update: if true;

      // Answers subcollection
      match /answers/{answerId} {
        allow read: if request.auth != null;
        allow write: if true;
      }
    }

    // App config (admin only)
    match /appConfigs/{configId} {
      allow read: if true;
      allow write: if request.auth != null &&
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'ADMIN';
    }
  }
}
```

### Indexes (akan dibuat otomatis saat diperlukan)

Firebase akan memberikan link untuk membuat index jika diperlukan saat development.

## 5. Verifikasi Setup

Jalankan app dan cek console log:

```
[Firebase/Core] Configuration successful
```

Jika ada error, pastikan:
- ✅ GoogleService-Info.plist ada di target
- ✅ Bundle ID cocok
- ✅ Firebase SDK sudah ditambahkan
- ✅ FirebaseApp.configure() dipanggil di init

## 6. Environment Variables (Optional)

Untuk development, bisa gunakan Firebase Emulator:

```bash
firebase emulators:start --only firestore
```

Update connection di code:

```swift
let settings = Firestore.firestore().settings
settings.host = "localhost:8080"
settings.isSSLEnabled = false
Firestore.firestore().settings = settings
```

## Troubleshooting

### Error: "Could not locate configuration file"
- Pastikan GoogleService-Info.plist ada di bundle

### Error: "Unable to fetch document"
- Cek Firestore rules
- Pastikan collection sudah dibuat

### Error: "Network error"
- Cek koneksi internet
- Cek Firestore quota di Firebase Console

---

**Status:** ✅ Ready for implementation setelah setup di atas selesai
