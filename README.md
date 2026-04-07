# EduTrack — College Management App

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)
![Dart](https://img.shields.io/badge/Dart-Language-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

EduTrack is a Flutter-based mobile application built for colleges and universities.
It provides secure, role-based access for students and teachers — streamlining
attendance tracking, marks management, and student records in one place.

---

## ✨ Features

### 👨‍🏫 Teacher
- View and manage the full student list
- Add new students to the system
- Mark daily attendance
- Upload internal and external marks

### 👨‍🎓 Student
- View personal attendance records
- Check attendance percentage at a glance

### 🎨 General
- Role-based authentication via Supabase
- Material Design 3 UI with a navy blue theme
- Google Fonts & SVG rendering

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) |
| Backend | Supabase (Auth + Database) |
| UI | Material Design 3, Google Fonts |

---

## 🚀 Setup Instructions

### 1. Clone the repo
```bash
git clone https://github.com/basavarajpatil660/EduTrack.git
cd EduTrack
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Configure Supabase
- Create a free project at [supabase.com](https://supabase.com)
- Open the **SQL Editor** in your Supabase dashboard
- Run the `supabase_schema.sql` file to set up all tables and policies
- In `lib/main.dart`, replace the placeholder values:
```dart
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```
> Find these in: Supabase Dashboard → Project Settings → API

### 4. Run the app
```bash
flutter run
```

---

## 📁 Folder Structure
EduTrack/
├── lib/
│   ├── screens/        # All app screens (login, dashboard, attendance, marks...)
│   ├── widgets/        # Reusable UI components
│   └── main.dart       # App entry point & Supabase config
├── supabase_schema.sql # Full database schema & RLS policies
└── pubspec.yaml        # Dependencies

---

## 🔐 Security Notice

Supabase credentials (URL and Anon Key) have been intentionally removed
from this repository. Never commit API keys to a public repo.
Follow Step 3 above to add your own credentials before running the project.

---

## 👨‍💻 Developer

Made by [Basavaraj Patil](https://github.com/basavarajpatil660)
