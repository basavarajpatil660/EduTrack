# EduTrack

> A role-based college management app — attendance, marks, and student records in one place.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=flat-square&logo=supabase&logoColor=black)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=flat-square&logo=postgresql&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-brightgreen?style=flat-square)
![Stars](https://img.shields.io/github/stars/basavarajpatil660/EduTrack?style=flat-square)
![Forks](https://img.shields.io/github/forks/basavarajpatil660/EduTrack?style=flat-square)

---

## 🔍 Problem Statement

Most colleges still track attendance and marks using paper registers or scattered
spreadsheets — leading to data loss, no real-time visibility for students, and heavy
manual work for teachers. There is no single, secure, role-aware platform built for
this workflow.

---

## 💡 Solution

EduTrack is a Flutter mobile app that gives **teachers** a complete toolkit to manage
students, mark attendance, and upload marks — while giving **students** instant, secure
access to their own academic records. Everything is powered by Supabase with Row Level
Security, ensuring no role can access data it shouldn't.

---

## ✨ Features

### 👨‍🏫 Teacher
- Secure role-based login and registration
- View and manage the full student list
- Add new students to the system
- Mark daily attendance per student
- Upload internal and external marks

### 👨‍🎓 Student
- Secure role-based login and registration
- View personal attendance records
- Track attendance percentage in real time
- View uploaded marks from teachers

### 🔐 General
- Material Design 3 UI with navy blue theme
- Google Fonts and SVG rendering
- PostgreSQL RLS policies — strict data isolation per role

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) |
| Backend | Supabase — Auth + PostgreSQL |
| Database | PostgreSQL with Row Level Security |
| UI System | Material Design 3, Google Fonts |

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

## 🚀 Installation

**1. Clone the repo**
```bash
git clone https://github.com/basavarajpatil660/EduTrack.git
cd EduTrack
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Set up Supabase**
- Create a free project at [supabase.com](https://supabase.com)
- Open the SQL Editor and run `supabase_schema.sql`

**4. Add your credentials in `lib/main.dart`**
```dart
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```
> Find these at: Supabase Dashboard → Project Settings → API

**5. Run the app**
```bash
flutter run
```

> ⚠️ Supabase credentials have been intentionally removed from this repo.
> Never commit API keys to a public repository.

---

## 📸 Screenshots

| Login | Teacher Dashboard | Student Dashboard |
|-------|------------------|------------------|
| coming soon | coming soon | coming soon |

---

## 🔮 Future Improvements

- [ ] Admin role with full system oversight
- [ ] Push notifications for low attendance warnings
- [ ] Timetable management module
- [ ] Dark mode support
- [ ] Play Store release

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!
Feel free to open an issue or submit a pull request.
Please follow standard GitHub flow — fork → branch → PR.

---

## 👨‍💻 Developer

Built by [Basavaraj Patil](https://github.com/basavarajpatil660)
