import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/bottom_nav.dart';

class MyMarks extends StatefulWidget {
  const MyMarks({super.key});

  @override
  State<MyMarks> createState() => _MyMarksState();
}

class _MyMarksState extends State<MyMarks> {
  bool _isLoading = true;
  int _semester = 1;
  String _batchName = '';
  
  double _gpa = 0.0;
  String _overallGrade = 'N/A';
  int _classRank = 0;
  int _totalStudents = 0;
  
  List<Map<String, dynamic>> _subjectMarks = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. Fetch User Data
      final userData = await Supabase.instance.client
          .from('users')
          .select('batch, semester')
          .eq('id', user.id)
          .single();
      
      _batchName = userData['batch'] ?? '';
      _semester = userData['semester'] ?? 1;

      // 2. Fetch Subjects for this semester
      final subjectsData = await Supabase.instance.client
          .from('subjects')
          .select('id, code, name')
          .eq('semester', _semester);

      // 3. Fetch Marks for this user
      final marksData = await Supabase.instance.client
          .from('marks')
          .select('subject_id, internal, external, total')
          .eq('student_id', user.id);

      List<Map<String, dynamic>> subMarks = [];
      int grandTotal = 0;
      int maxGrandTotal = subjectsData.length * 100;

      for (var sub in subjectsData) {
        final subId = sub['id'];
        final relatedMark = marksData.cast<Map<String, dynamic>>().firstWhere(
              (m) => m['subject_id'] == subId,
              orElse: () => {'internal': 0, 'external': 0, 'total': 0},
            );

        int internal = relatedMark['internal'];
        int external = relatedMark['external'];
        int total = relatedMark['total'];
        
        grandTotal += total;

        subMarks.add({
          'code': sub['code'],
          'name': sub['name'],
          'internal': internal,
          'external': external,
          'total': total,
        });
      }

      // Calculate GPA
      if (subjectsData.isNotEmpty) {
        double avg = grandTotal / subjectsData.length;
        _gpa = avg / 10; // Simple GPA scale out of 10
        _overallGrade = _getGradeLabel(avg);
      }

      // 4. Calculate Rank
      if (_batchName.isNotEmpty) {
        final classmatesData = await Supabase.instance.client
            .from('users')
            .select('id')
            .eq('batch', _batchName)
            .eq('semester', _semester)
            .eq('role', 'student');
            
        _totalStudents = classmatesData.length;
        
        if (_totalStudents > 0) {
          final classmateIds = classmatesData.map((e) => e['id']).toList();
          final allMarks = await Supabase.instance.client
              .from('marks')
              .select('student_id, total')
              .inFilter('student_id', classmateIds);
          
          Map<String, int> studentTotals = {};
          for (var id in classmateIds) {
            studentTotals[id] = 0;
          }
          
          for (var m in allMarks) {
            String sid = m['student_id'];
            studentTotals[sid] = (studentTotals[sid] ?? 0) + (m['total'] as int);
          }
          
          List<MapEntry<String, int>> sortedTotals = studentTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)); // Descending
            
          for (int i = 0; i < sortedTotals.length; i++) {
            if (sortedTotals[i].key == user.id) {
              _classRank = i + 1;
              break;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _subjectMarks = subMarks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading marks: $e')),
        );
      }
    }
  }

  String _getGradeLabel(num total) {
    if (total >= 90) return 'A+';
    if (total >= 80) return 'A';
    if (total >= 70) return 'B';
    if (total >= 60) return 'C';
    return 'F';
  }

  MaterialColor _getGradeColor(String grade) {
    if (grade == 'A+') return Colors.green;
    if (grade == 'A') return Colors.green;
    if (grade == 'B') return Colors.blue;
    if (grade == 'C') return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(title: const Text('My Marks')),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: const CustomBottomNav(
          currentIndex: 1,
          role: UserRole.student,
        ),
      );
    }

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
            'My Marks',
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
      body: _subjectMarks.isEmpty
          ? const Center(child: Text("No marks records found."))
          : SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
              child: Column(
                children: [
                  // Semester Selector
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Semester $_semester',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.expand_more, size: 20, color: colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Overall Performance Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.primaryContainer],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primaryContainer.withOpacity(0.2),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'OVERALL GPA',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                RichText(
                                  text: TextSpan(
                                    style: textTheme.displaySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Public Sans',
                                    ),
                                    children: [
                                      TextSpan(text: _gpa.toStringAsFixed(1)),
                                      TextSpan(
                                        text: ' / 10',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getGradeColor(_overallGrade)[50],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Grade: $_overallGrade',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _getGradeColor(_overallGrade)[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.leaderboard, color: colorScheme.onPrimaryContainer, size: 20),
                                const SizedBox(width: 8),
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.onPrimaryContainer,
                                      fontFamily: 'Public Sans',
                                    ),
                                    children: [
                                      const TextSpan(text: 'Class Rank: '),
                                      TextSpan(
                                        text: '$_classRank / $_totalStudents',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: 40,
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 16,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryFixed,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: colorScheme.primaryContainer, width: 2),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondaryContainer,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: colorScheme.primaryContainer, width: 2),
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

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Subject Wise Marks',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ..._subjectMarks.map((sub) => _buildMarkCard(
                        context,
                        sub['code'],
                        sub['name'],
                        _getGradeLabel(sub['total']),
                        _getGradeColor(_getGradeLabel(sub['total'])),
                        sub['internal'],
                        sub['external'],
                        sub['total'],
                        isAplus: _getGradeLabel(sub['total']) == 'A+',
                      ))
                ],
              ),
            ),
      bottomNavigationBar: const CustomBottomNav(
        currentIndex: 1,
        role: UserRole.student,
      ),
      ),
    );
  }

  Widget _buildMarkCard(BuildContext context, String code, String name, String grade,
      MaterialColor gradeColor, int internal, int external, int total, {bool isAplus = false}) {
    final colorScheme = Theme.of(context).colorScheme;

    Color labelBg = isAplus ? Colors.green[100]! : gradeColor[50]!;
    Color labelText = isAplus ? Colors.green[900]! : gradeColor[800]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
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
                  color: labelBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Grade $grade',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: labelText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colorScheme.surfaceContainerLow)),
            ),
            child: Row(
              children: [
                Expanded(child: _buildScoreColumn(context, 'Internal', internal, 30)),
                Container(width: 1, height: 32, color: colorScheme.surfaceContainerLow),
                Expanded(child: _buildScoreColumn(context, 'External', external, 70)),
                Container(width: 1, height: 32, color: colorScheme.surfaceContainerLow),
                Expanded(child: _buildScoreColumn(context, 'Total', total, 100, isTotal: true)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreColumn(BuildContext context, String label, int score, int max, {bool isTotal = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? colorScheme.primary : colorScheme.onSurface,
              fontFamily: 'Public Sans',
            ),
            children: [
              TextSpan(text: '$score'),
              TextSpan(
                text: '/$max',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
