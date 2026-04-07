import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/bottom_nav.dart';
import 'my_marks.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  bool _isLoading = true;
  String _name = '';
  String _batchName = '';
  int _semester = 0;
  
  double _attendancePercentage = 0.0;
  int _unreadNotices = 0;
  String _latestNoticeTitle = 'No Notices';
  String _latestNoticeMessage = 'You are all caught up!';
  String _nextSubject = 'No classes';
  List<Map<String, dynamic>> _todaysClasses = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Fetch User Data
      final userData = await Supabase.instance.client
          .from('users')
          .select('name, batch, semester')
          .eq('id', user.id)
          .single();

      _name = userData['name'] ?? 'Student';
      _batchName = userData['batch'] ?? 'Batch';
      _semester = userData['semester'] ?? 1;

      // Fetch Attendance (calculate %)
      final attendanceData = await Supabase.instance.client
          .from('attendance')
          .select('status')
          .eq('student_id', user.id);
          
      if (attendanceData.isNotEmpty) {
        int presentCount = attendanceData.where((a) => a['status'] == 'present').length;
        _attendancePercentage = presentCount / attendanceData.length;
      }

      // Fetch Notices
      final noticesData = await Supabase.instance.client
          .from('notices')
          .select()
          .order('created_at', ascending: false);
          
      _unreadNotices = noticesData.where((n) => n['is_read'] == false).length;
      if (noticesData.isNotEmpty) {
        _latestNoticeTitle = noticesData.first['title'] ?? 'Notice';
        _latestNoticeMessage = noticesData.first['message'] ?? '';
      }

      // Fetch Next Subject based on Semester
      final subjectsData = await Supabase.instance.client
          .from('subjects')
          .select('id, name')
          .eq('semester', _semester);
          
      if (subjectsData.isNotEmpty) {
        _nextSubject = "Next: ${subjectsData.first['name']}";
      }

      // Format today's date
      final DateTime now = DateTime.now();
      final String todayDateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // Fetch today's attendance
      final todaysAttendance = await Supabase.instance.client
          .from('attendance')
          .select('subject_id, status')
          .eq('student_id', user.id)
          .eq('date', todayDateStr);

      _todaysClasses.clear();
      for (var sub in subjectsData) {
        String status = 'Not Marked';
        for (var att in todaysAttendance) {
          if (att['subject_id'] == sub['id']) {
            status = att['status'] == 'present' ? 'Present' : 'Absent';
            break;
          }
        }
        _todaysClasses.add({
          'subject': sub['name'],
          'status': status,
        });
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
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
            role: UserRole.student,
          ),
        ),
      );
    }

    final firstName = _name.split(' ').first;
    final initials = firstName.isNotEmpty ? firstName.substring(0, 1).toUpperCase() : '?';

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
                radius: 18,
                backgroundColor: colorScheme.primaryFixed,
                child: Text(
                  initials,
                  style: TextStyle(
                    color: colorScheme.onPrimaryFixed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Text(
              'Welcome, $firstName 👋',
              style: textTheme.headlineMedium?.copyWith(
                color: colorScheme.primary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$_batchName — Sem $_semester',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 32),

            // Bento Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: [
                _buildAttendanceCard(context),
                _buildMarksCard(context),
                _buildTimetableCard(context),
                _buildNoticesCard(context),
              ],
            ),
            const SizedBox(height: 32),

            // Today's Classes Section
            _buildTodaysClassesSection(context),
            const SizedBox(height: 32),

            // Editorial Event Section
            _buildEventSection(context),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(
        currentIndex: 0,
        role: UserRole.student,
      ),
      ),
    );
  }

  Widget _buildTodaysClassesSection(BuildContext context) {
    if (_todaysClasses.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Classes",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        ..._todaysClasses.map((cls) {
          IconData icon;
          Color color;
          if (cls['status'] == 'Present') {
            icon = Icons.check_circle;
            color = Colors.green;
          } else if (cls['status'] == 'Absent') {
            icon = Icons.cancel;
            color = Colors.red;
          } else {
            icon = Icons.hourglass_empty;
            color = Colors.orange;
          }
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(cls['subject'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Status: ${cls['status']}'),
              trailing: Icon(icon, color: color),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAttendanceCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final String percentText = (_attendancePercentage * 100).toStringAsFixed(0);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'ATTENDANCE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: _attendancePercentage,
                    strokeWidth: 8,
                    backgroundColor: colorScheme.surfaceContainer,
                    color: _attendancePercentage >= 0.75 ? colorScheme.secondary : colorScheme.error,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '$percentText%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _attendancePercentage >= 0.75 
                ? colorScheme.secondaryContainer.withOpacity(0.3)
                : colorScheme.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _attendancePercentage >= 0.75 ? 'ON TRACK' : 'LOW ATTENDANCE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _attendancePercentage >= 0.75 ? colorScheme.secondary : colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarksCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, a1, a2) => const MyMarks(),
            transitionDuration: Duration.zero,
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MARKS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.book, size: 20, color: Colors.white),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Academic\nPerformance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'View Marks',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 14, color: colorScheme.onPrimaryContainer),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TIMETABLE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.calendar_today, size: 20, color: colorScheme.onSecondaryContainer),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today\'s\nClasses',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _nextSubject,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoticesCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NOTICES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.notifications, size: 20, color: colorScheme.primary),
                  ),
                  if (_unreadNotices > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_unreadNotices',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              Text(
                'UNREAD NOTICES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -32,
            bottom: -32,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: colorScheme.secondary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Icon(
              Icons.campaign,
              size: 48,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LATEST NOTICE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _latestNoticeTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _latestNoticeMessage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: colorScheme.primary,
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Read More',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
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
