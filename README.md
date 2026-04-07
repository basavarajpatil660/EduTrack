# EduTrack — College Management App

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=flat-square&logo=supabase&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=flat-square&logo=postgresql&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-brightgreen?style=flat-square)

> A role-based college management app for students and teachers —
> built with Flutter and powered by Supabase.

---

## 📖 Project Overview

EduTrack is a mobile application designed for colleges and universities.
It provides a clean, secure platform where **teachers** can manage students,
track attendance, and upload marks — while **students** can monitor their
own academic progress in real time.

---

## ✨ Features

### 👨‍🏫 Teacher
- Secure login and registration
- View full student list
- Add new students to the system
- Mark daily attendance
- Upload internal and external marks

### 👨‍🎓 Student
- Secure login and registration
- View personal attendance records
- Check attendance percentage
- View uploaded marks

### 🔐 General
- Role-based authentication (Teacher / Student)
- Secure backend with Row Level Security (RLS)
- Material Design 3 UI with navy blue theme
- Google Fonts & SVG rendering

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) |
| Backend | Supabase (Auth + PostgreSQL) |
| Database | PostgreSQL with RLS Policies |
| UI | Material Design 3, Google Fonts |
| State | Flutter setState |

---

## 📁 Project Structure
EduTrack/
├── lib/
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── teacher_dashboard.dart
│   │   ├── student_dashboard.dart
│   │   ├── students_list.dart
│   │   ├── add_student.dart
│   │   ├── mark_attendance.dart
│   │   ├── my_attendance.dart
│   │   ├── upload_marks.dart
│   │   ├── my_marks.dart
│   │   ├── profile_screen.dart
│   │   └── reports.dart
│   ├── widgets/
│   │   └── bottom_nav.dart
│   ├── theme.dart
│   └── main.dart
├── supabase_schema.sql
└── pubspec.yaml

---

## 🚀 Installation & Setup

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed
- A free [Supabase](https://supabase.com) account

### Steps

**1. Clone the repository**
```bash
git clone https://github.com/basavarajpatil660/EduTrack.git
cd EduTrack
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Set up Supabase**
- Create a new project at [supabase.com](https://supabase.com)
- Go to **SQL Editor** in your Supabase dashboard
- Run the `supabase_schema.sql` file to create all tables and policies

**4. Add your credentials**

In `lib/main.dart`, replace the placeholders:
```dart
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```
> **Find these at:** Supabase Dashboard → Project Settings → API

**5. Run the app**
```bash
flutter run
```

---

## 🔐 Security Notice

Supabase credentials have been intentionally removed from this repository.
Never commit API keys to a public repo.
Follow **Step 4** above to add your own credentials before running the project.

---

## 👨‍💻 Developer

Built by [Basavaraj Patil](https://github.com/basavarajpatil660)
