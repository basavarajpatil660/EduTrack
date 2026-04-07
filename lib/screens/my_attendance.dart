import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/bottom_nav.dart';

class MyAttendance extends StatefulWidget {
  const MyAttendance({super.key});

  @override
  State<MyAttendance> createState() => _MyAttendanceState();
}

class _MyAttendanceState extends State<MyAttendance> {
  bool _isLoading = true;
  int _semester = 1;
  int _totalPresent = 0;
  int _totalAbsent = 0;
  List<Map<String, dynamic>> _subjectWise = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. Fetch User Semester
      final userData = await Supabase.instance.client
          .from('users')
          .select('semester')
          .eq('id', user.id)
          .single();
      
      _semester = userData['semester'] ?? 1;

      // 2. Fetch Subjects for this semester
      final subjectsData = await Supabase.instance.client
          .from('subjects')
          .select('id, code, name')
          .eq('semester', _semester);

      // 3. Fetch Attendance for this user
      final attendanceData = await Supabase.instance.client
          .from('attendance')
          .select('subject_id, status')
          .eq('student_id', user.id);

      int totalPres = 0;
      int totalAbs = 0;
      List<Map<String, dynamic>> subjectStats = [];

      for (var sub in subjectsData) {
        final subId = sub['id'];
        final relatedAttendance = attendanceData.where((a) => a['subject_id'] == subId).toList();
        
        int pres = relatedAttendance.where((a) => a['status'] == 'present').length;
        int abs = relatedAttendance.where((a) => a['status'] == 'absent').length;
        int total = pres + abs;
        
        totalPres += pres;
        totalAbs += abs;
        
        double percentage = total == 0 ? 0.0 : (pres / total);
        
        subjectStats.add({
          'code': sub['code'],
          'name': sub['name'],
          'present': pres,
          'total': total,
          'percentage': percentage,
        });
      }

      if (mounted) {
        setState(() {
          _totalPresent = totalPres;
          _totalAbsent = totalAbs;
          _subjectWise = subjectStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading attendance: $e')),
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
          appBar: AppBar(title: const Text('Attendance')),
          body: const Center(child: CircularProgressIndicator()),
          bottomNavigationBar: const CustomBottomNav(
            currentIndex: 2,
            role: UserRole.student,
          ),
        ),
      );
    }

    final totalLectures = _totalPresent + _totalAbsent;
    final overallPercentage = totalLectures == 0 ? 0.0 : (_totalPresent / totalLectures);
    final String percentText = (overallPercentage * 100).toStringAsFixed(0);

    return WillPopScope(
      onWillPop: () async {
        if (Navigator.canPop(context)) {
          return true;
        }
        return false;
      },
      child: Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          backgroundColor: Colors.white.withOpacity(0.9),
          elevation: 0,
          scrolledUnderElevation: 4,
          shadowColor: Colors.black.withOpacity(0.05),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.primary),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          centerTitle: true,
          title: Text(
            'Attendance',
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: totalLectures == 0 && _subjectWise.isEmpty
          ? const Center(child: Text("No attendance records found."))
          : SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 100),
              child: Column(
                children: [
                  // Overall Attendance Summary Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -16,
                          right: -16,
                          child: Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.primaryFixed.withOpacity(0.2),
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 160,
                                    height: 160,
                                    child: CircularProgressIndicator(
                                      value: overallPercentage,
                                      strokeWidth: 16,
                                      backgroundColor: colorScheme.surfaceContainer,
                                      color: overallPercentage >= 0.75 ? Colors.teal[500] : colorScheme.error,
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ),
                                  Text(
                                    '$percentText%',
                                    style: textTheme.displaySmall?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$_totalPresent',
                                  style: textTheme.headlineSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'PRESENT',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    '|',
                                    style: TextStyle(color: colorScheme.outlineVariant),
                                  ),
                                ),
                                Text(
                                  '$_totalAbsent',
                                  style: textTheme.headlineSmall?.copyWith(
                                    color: colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ABSENT',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Public Sans',
                                  ),
                                  children: [
                                    const TextSpan(text: 'Total Lectures: '),
                                    TextSpan(
                                      text: '$totalLectures',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.amber[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.amber[800], size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Minimum 75% required',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Subject Wise',
                        style: textTheme.headlineSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'SEM $_semester',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  ..._subjectWise.map((sub) => _buildSubjectCard(
                    context, 
                    sub['code'] ?? '', 
                    sub['name'] ?? '', 
                    sub['percentage'] as double,
                    (sub['percentage'] as double) >= 0.75,
                  )),
                ],
              ),
            ),
      bottomNavigationBar: const CustomBottomNav(
        currentIndex: 2,
        role: UserRole.student,
      ),
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, String code, String name, double progress, bool isGood) {
    final colorScheme = Theme.of(context).colorScheme;
    final int percentage = (progress * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryFixed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        code,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isGood ? Colors.teal[50] : colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isGood ? Colors.teal[800] : colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: colorScheme.surfaceContainer,
            color: isGood ? Colors.teal[500] : colorScheme.error,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
