# EduTrack College App

EduTrack is a comprehensive Flutter-based mobile application designed for colleges and universities. It provides role-based access for both students and teachers, streamlining attendance tracking, marks management, and student information over a secure platform.

## Features

- **Role-based Authentication:** Secure login for students and teachers using Supabase.
- **Teacher Workspace:**
  - View and manage student lists.
  - Add new students to the system.
  - Mark daily attendance.
  - Upload internal and external marks.
- **Student Workspace:**
  - View personal attendance records.
  - Check attendance percentages.
- **Modern UI:** Built with Material Design 3 and a consistent navy blue color scheme.

## Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Supabase (Auth & Realtime Database)
- **Assets/Styling:** Material 3, Google Fonts, SVG rendering

## Setup Instructions

1. **Clone the repo**
   ```bash
   git clone <your_github_repo_url>
   ```
   
2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Database Configuration**
   - Head over to Supabase and create a new project.
   - Run the `supabase_schema.sql` file in your Supabase SQL Editor to set up all tables and security policies.
   - Update `main.dart` with your Supabase URL and Anon Key.
   
4. **Run the App**
   ```bash
   flutter run
   ```

## Folder Structure

- `lib/`: Contains the Dart source files.
  - `screens/`: All page templates and screens.
  - `widgets/`: Reusable functional flutter widgets.
- `supabase_schema.sql`: Your backend structure and policies for an easy reproduction of the DB in Supabase.
