import 'package:flutter/material.dart';
import '../screens/student_dashboard.dart';
import '../screens/teacher_dashboard.dart';
import '../screens/my_attendance.dart';
import '../screens/my_marks.dart';
import '../screens/mark_attendance.dart';
import '../screens/profile_screen.dart';

enum UserRole { student, teacher }

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final UserRole role;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    if (role == UserRole.teacher) {
      return _buildTeacherNav(context);
    } else {
      return _buildStudentNav(context);
    }
  }

  Widget _buildTeacherNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 12,
          )
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 'Home', Icons.home_outlined, Icons.home, 0, () {
                _navigate(context, const TeacherDashboard());
              }),
              _buildNavItem(context, 'Attendance', Icons.fact_check_outlined, Icons.fact_check, 1, () {
                _navigate(context, const MarkAttendance());
              }),
              _buildNavItem(context, 'Profile', Icons.person_outline, Icons.person, 3, () {
                _navigate(context, const ProfileScreen(role: UserRole.teacher));
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, -8),
            blurRadius: 32,
          )
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 'Home', Icons.dashboard_outlined, Icons.dashboard, 0, () {
                _navigate(context, const StudentDashboard());
              }),
              _buildNavItem(context, 'Academics', Icons.school_outlined, Icons.school, 1, () {
                _navigate(context, const MyMarks());
              }),
              _buildNavItem(context, 'Schedule', Icons.calendar_today_outlined, Icons.calendar_today, 2, () {
                _navigate(context, const MyAttendance());
              }),
              _buildNavItem(context, 'Profile', Icons.person_outline, Icons.person, 3, () {
                _navigate(context, const ProfileScreen(role: UserRole.student));
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => screen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String label, IconData iconOutlined, IconData iconFilled, int index, VoidCallback onTap) {
    final isActive = currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: isActive ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? iconFilled : iconOutlined,
              color: isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
