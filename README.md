<h1 align="center">
  <img src="https://readme-typing-svg.herokuapp.com?font=Fira+Code&size=28&pause=1000&color=02569B&center=true&vCenter=true&width=500&lines=EduTrack+%F0%9F%8E%93;College+Management+App" alt="EduTrack" />
</h1>

<p align="center">
  <b>A role-based college management app — attendance, marks, and student records in one place.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white"/>
  <img src="https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=black"/>
  <img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white"/>
  <img src="https://img.shields.io/badge/License-MIT-brightgreen?style=for-the-badge"/>
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/basavarajpatil660/EduTrack?style=social"/>
  &nbsp;
  <img src="https://img.shields.io/github/forks/basavarajpatil660/EduTrack?style=social"/>
  &nbsp;
  <img src="https://img.shields.io/github/issues/basavarajpatil660/EduTrack?style=social"/>
</p>

---

## 🔍 Problem Statement

Most colleges still manage attendance and marks using paper registers or
scattered spreadsheets — causing data loss, no real-time visibility for
students, and heavy manual work for teachers.

**EduTrack solves this.**

---

## 💡 What EduTrack Does

EduTrack is a Flutter mobile app that gives **teachers** a complete toolkit
to manage students, mark attendance, and upload marks — while giving
**students** instant, secure access to their own academic records.

Everything is powered by **Supabase** with Row Level Security (RLS),
ensuring every role only sees data it's allowed to.

---

## ✨ Features

### 👨‍🏫 Teacher
- ✅ Secure role-based login & registration
- ✅ View and manage full student list
- ✅ Add new students to the system
- ✅ Mark daily attendance per student
- ✅ Upload internal and external marks

### 👨‍🎓 Student
- ✅ Secure role-based login & registration
- ✅ View personal attendance records
- ✅ Track attendance percentage in real time
- ✅ View marks uploaded by teachers

### 🔐 Security & UI
- ✅ PostgreSQL RLS — strict data isolation per role
- ✅ Material Design 3 with navy blue theme
- ✅ Google Fonts & SVG rendering

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| 📱 Frontend | Flutter (Dart) |
| ☁️ Backend | Supabase (Auth + PostgreSQL) |
| 🗄️ Database | PostgreSQL with RLS Policies |
| 🎨 UI System | Material Design 3, Google Fonts |
| 🔧 Version Control | Git + GitHub |

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
├── CONTRIBUTING.md
├── LICENSE
└── pubspec.yaml

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed
- A free [Supabase](https://supabase.com) account
- Android Studio or VS Code

### Installation

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
- Open **SQL Editor** in your Supabase dashboard
- Copy and run the contents of `supabase_schema.sql`

**4. Add your credentials**

In `lib/main.dart`, replace the placeholders:
```dart
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```
> 📍 Find these at: **Supabase Dashboard → Project Settings → API**

**5. Run the app**
```bash
flutter run
```

> ⚠️ **Security Notice:** Supabase credentials have been intentionally
> removed from this repository. Never commit API keys to a public repo.

---

## 📱 Usage

| Role | How to use |
|------|-----------|
| Teacher | Register with Teacher role → manage students, mark attendance, upload marks |
| Student | Register with Student role → view your attendance and marks |

---

## 📸 Screenshots

| Login | Teacher Dashboard | Student Dashboard |
|-------|-----------------|-----------------|
| *Coming soon* | *Coming soon* | *Coming soon* |

> Screenshots will be added after APK build is complete.

---

## 🔮 Future Improvements

- [ ] 🔔 Push notifications for low attendance warnings
- [ ] 👤 Admin role with full system oversight
- [ ] 📅 Timetable management module
- [ ] 🌙 Dark mode support
- [ ] 📊 Detailed analytics and reports
- [ ] 🚀 Publish on Google Play Store

---

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md)
before submitting a pull request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License.
See the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Developer

<p align="center">
  Built with ❤️ by
  <a href="https://github.com/basavarajpatil660"><b>Basavaraj Patil</b></a>
  <br/>
  🇮🇳 Hubballi, Karnataka, India
</p>

<p align="center">
  <img src="https://github-readme-stats.vercel.app/api?username=basavarajpatil660&show_icons=true&theme=tokyonight&hide_border=true"/>
</p>
