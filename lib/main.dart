import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/teacher_dashboard.dart';
import 'screens/mark_attendance.dart';
import 'screens/my_attendance.dart';
import 'screens/my_marks.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase (Use your project credentials)
  await Supabase.initialize(
    url: 'https://dpbvopdmyelattjcwrmy.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwYnZvcGRteWVsYXR0amN3cm15Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwMTcxOTcsImV4cCI6MjA4OTU5MzE5N30.C_IhhjCNr5z_59ZQeEyumt862od-orMAhmBriU8vv5c',
  );

  runApp(const EduTrackApp());
}

class EduTrackApp extends StatelessWidget {
  const EduTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        // Handle signed in (already handled by stream builder below, but can add side effects)
      }
    });
  }

  Future<String?> _getUserRole(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      
      if (data == null) {
        return null; // No profile found
      }
      
      return data['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;

        // If not logged in, show Login Screen
        if (session == null) {
          return const LoginScreen();
        }

        // If logged in, fetch user role to decide which dashboard to show
        return FutureBuilder<String?>(
          future: _getUserRole(session.user.id),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            
            final role = roleSnapshot.data;
            if (role == null) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Access Denied'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () => Supabase.instance.client.auth.signOut(),
                    ),
                  ],
                ),
                body: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'Account not set up. Contact administrator.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ),
              );
            }
            
            if (role == 'teacher') {
              return const TeacherDashboard();
            } else {
              return const StudentDashboard();
            }
          },
        );
      },
    );
  }
}
