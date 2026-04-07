import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../widgets/bottom_nav.dart';
import 'mark_attendance.dart';
import 'upload_marks.dart';
import 'students_list.dart';
import 'reports.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  bool _isLoading = true;
  String _name = '';
  int _classCount = 0;
  int _studentCount = 0;
  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. Fetch Teacher Profile
      final userData = await Supabase.instance.client
          .from('users')
          .select('name')
          .eq('id', user.id)
          .single();
      
      _name = userData['name'] ?? 'Teacher';

      // 2. Fetch Classes / Subjects count
      final subjectsData = await Supabase.instance.client
          .from('subjects')
          .select('id, semester')
          .eq('teacher_id', user.id);
          
      _classCount = subjectsData.length;

      // 3. Fetch Student Count (All students in college)
      final studentsData = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('role', 'student');
      _studentCount = studentsData.length;

      // 4. Fetch Recent Activity
      final activityData = await Supabase.instance.client
          .from('teacher_activity')
          .select()
          .eq('teacher_id', user.id)
          .order('created_at', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          _recentActivities = activityData.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return WillPopScope(
        onWillPop: () async {
          if (Navigator.canPop(context)) return true;
          return false;
        },
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          body: const Center(child: CircularProgressIndicator()),
          bottomNavigationBar: const CustomBottomNav(
            currentIndex: 0,
            role: UserRole.teacher,
          ),
        ),
      );
    }

    final lastName = _name.split(' ').length > 1 ? _name.split(' ').last : _name;

    return WillPopScope(
      onWillPop: () async {
        if (Navigator.canPop(context)) return true;
        return false;
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(72),
        child: AppBar(
          backgroundColor: colorScheme.surface.withOpacity(0.9),
          elevation: 0,
          scrolledUnderElevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ColorFilter.mode(
                colorScheme.surface.withOpacity(0.8),
                BlendMode.srcOver,
              ),
              child: Container(),
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.menu, color: colorScheme.primary),
            onPressed: () {},
          ),
          title: Text(
            'EduTrack',
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
              letterSpacing: -0.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primaryContainer,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: colorScheme.secondaryContainer,
                  child: Text(
                    lastName.isNotEmpty ? lastName.substring(0, 1).toUpperCase() : 'T',
                    style: TextStyle(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Text(
              'Welcome, Prof. $lastName 👋',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Computer Science Department',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 24),

            // Summary Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_today, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CURRENT SCHEDULE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Today: $_classCount Classes | $_studentCount Students',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: colorScheme.primaryFixed.withOpacity(0.5), size: 16),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bento Grid Action Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildActionCard(
                  context,
                  title: 'Mark Attendance',
                  subtitle: 'Quick check-in',
                  icon: Icons.fact_check,
                  iconBgColor: colorScheme.primaryContainer,
                  iconColor: Colors.white,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, a1, a2) => const MarkAttendance(),
                        transitionDuration: Duration.zero,
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  title: 'Upload Marks',
                  subtitle: 'Enter grades',
                  icon: Icons.upload,
                  iconBgColor: const Color(0xFF4586E2),
                  iconColor: Colors.white,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UploadMarks()),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  title: 'Students List',
                  subtitle: '$_studentCount Students',
                  icon: Icons.group,
                  iconBgColor: colorScheme.secondaryContainer,
                  iconColor: colorScheme.onSecondaryContainer,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StudentsList()),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  title: 'Reports',
                  subtitle: 'View Reports',
                  icon: Icons.bar_chart,
                  iconBgColor: colorScheme.surfaceContainerHighest,
                  iconColor: colorScheme.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReportsScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Recent Activity Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'VIEW ALL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentActivities.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No recent activities'),
              ))
            else
              Column(
                children: _recentActivities.map((act) => Column(
                  children: [
                    _buildActivityItem(
                      context,
                      actionText: "${act['action']} ",
                      highlightText: act['target'] ?? '',
                      timeText: _formatTime(act['created_at']),
                      icon: Icons.history,
                      iconColor: colorScheme.primaryContainer,
                    ),
                    const SizedBox(height: 12),
                  ],
                )).toList(),
              ),
            const SizedBox(height: 80), // Padding for bottom nav
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(
        currentIndex: 0,
        role: UserRole.teacher,
      ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, {
    required String actionText,
    required String highlightText,
    required String timeText,
    required IconData icon,
    required Color iconColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                      fontFamily: 'Public Sans',
                    ),
                    children: [
                      TextSpan(text: actionText),
                      TextSpan(
                        text: highlightText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
